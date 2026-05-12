"""
Voice input daemon for Claude Code.
단축키 토글로 음성을 녹음 → Google Web Speech로 전사 → 터미널에 자동 입력.
무료, API 키 불필요. 인터넷 연결 필요.

사용법:
    python voice_input.py
    python voice_input.py --hotkey "alt+`" --lang ko-KR
"""

import argparse
import logging
import os
import platform
import sys
import tempfile
import threading
import time
import wave
from typing import Optional

import keyboard
import numpy as np
import PIL.Image
import PIL.ImageDraw
import pyperclip
import pystray
import sounddevice as sd
import speech_recognition as sr

# ── 상수 ───────────────────────────────────────────────────────────────────────
_LOG_PATH = os.path.expanduser("~/.claude/voice/voice.log")
_STATE_PATH = os.path.expanduser("~/.claude/voice/state")
SAMPLE_RATE = 16_000
CHANNELS = 1
MAX_RECORD_SECONDS = 300
_MAX_SAMPLES = MAX_RECORD_SECONDS * SAMPLE_RATE

_PASTE_SETUP_DELAY = 0.05    # ctrl+v 전 클립보드 안정화 대기
_PASTE_RESTORE_DELAY = 0.10  # ctrl+v 완료 후 클립보드 복원 대기
_IS_WINDOWS = platform.system() == "Windows"

_TITLE_IDLE = "🎤 Voice Input — 대기 중"
_TITLE_REC = "🔴 녹음 중..."

# ── 로깅 (파일 + 콘솔 통합) ────────────────────────────────────────────────────
logging.basicConfig(
    filename=_LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger(__name__)
_console = logging.StreamHandler(sys.stdout)
_console.setFormatter(logging.Formatter("%(message)s"))
log.addHandler(_console)

# ── 트레이 아이콘 (import 시 1회 생성) ────────────────────────────────────────
def _make_icon(recording: bool) -> PIL.Image.Image:
    img = PIL.Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = PIL.ImageDraw.Draw(img)
    color = (220, 50, 50) if recording else (120, 120, 120)
    draw.ellipse([4, 4, 60, 60], fill=color)
    draw.rectangle([26, 18, 38, 40], fill="white")
    draw.ellipse([22, 14, 42, 34], fill="white")
    draw.arc([20, 32, 44, 50], start=0, end=180, fill="white", width=3)
    draw.line([32, 50, 32, 56], fill="white", width=3)
    draw.line([26, 56, 38, 56], fill="white", width=3)
    return img


_ICON_IDLE = _make_icon(False)
_ICON_REC = _make_icon(True)


def beep(freq: int, duration_ms: int) -> None:
    if _IS_WINDOWS:
        import winsound
        winsound.Beep(freq, duration_ms)
    else:
        sys.stdout.write("\a")
        sys.stdout.flush()


def _write_wav(path: str, audio_data: np.ndarray) -> None:
    with wave.open(path, "wb") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(2)  # int16 = 2 bytes
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(audio_data.tobytes())


class VoiceRecorder:
    def __init__(self, lang: str = "ko-KR", tray: Optional[pystray.Icon] = None):
        self.lang = lang
        self.tray = tray
        self.recording = False
        self._frames: list[np.ndarray] = []
        self._sample_count = 0
        self._lock = threading.Lock()
        self._stream: Optional[sd.InputStream] = None
        self._recognizer = sr.Recognizer()

    def _update_tray(self, recording: bool) -> None:
        if self.tray is None:
            return
        self.tray.icon = _ICON_REC if recording else _ICON_IDLE
        self.tray.title = _TITLE_REC if recording else _TITLE_IDLE
        try:
            with open(_STATE_PATH, "w", encoding="utf-8") as _f:
                _f.write("recording" if recording else "idle")
        except OSError:
            pass

    def _audio_callback(self, indata: np.ndarray, frames: int, time_info: object, status: object) -> None:
        with self._lock:
            if not self.recording:
                return
            self._sample_count += indata.shape[0]
            if self._sample_count > _MAX_SAMPLES:
                if self._sample_count - indata.shape[0] <= _MAX_SAMPLES:
                    log.warning("최대 녹음 시간(%d초)에 도달했습니다. 단축키를 눌러 전사하세요.", MAX_RECORD_SECONDS)
                return
            self._frames.append(indata.copy())

    def _start(self) -> None:
        with self._lock:
            self._frames = []
            self._sample_count = 0
        self.recording = True
        self._update_tray(True)
        self._stream = sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            dtype="int16",
            callback=self._audio_callback,
        )
        self._stream.start()
        beep(800, 200)
        log.info("[녹음 시작] 말씀하세요... (단축키를 다시 누르면 종료)")

    def _stop(self) -> Optional[np.ndarray]:
        self.recording = False
        self._update_tray(False)
        if self._stream:
            self._stream.stop()
            self._stream.close()
            self._stream = None
        beep(1200, 200)
        log.info("[녹음 종료] 전사 중...")
        with self._lock:
            frames_snapshot = self._frames[:]
            self._frames = []
        if not frames_snapshot:
            log.warning("[WARN] 녹음된 오디오가 없습니다.")
            return None
        return np.concatenate(frames_snapshot, axis=0)

    def _transcribe(self, audio_data: np.ndarray) -> Optional[str]:
        tmp_path = ""
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                tmp_path = tmp.name
            _write_wav(tmp_path, audio_data)
            with sr.AudioFile(tmp_path) as source:
                audio = self._recognizer.record(source)
            text = self._recognizer.recognize_google(audio, language=self.lang)
            log.info("[전사 완료] %s", text)
            return text
        except sr.UnknownValueError:
            log.warning("[WARN] 음성을 인식하지 못했습니다.")
        except sr.RequestError as e:
            log.error("[ERROR] 인터넷 연결을 확인하세요: %s", e)
        except Exception as e:
            log.exception("[ERROR] 전사 중 오류: %s", e)
        finally:
            if tmp_path:
                try:
                    os.unlink(tmp_path)
                except OSError as e:
                    log.warning("임시 파일 삭제 실패: %s", e)
        return None

    def _inject(self, text: str) -> None:
        # keyboard.write()는 CJK 문자를 일부 플랫폼에서 제대로 입력하지 못해
        # 클립보드 경유 붙여넣기를 사용한다.
        previous = pyperclip.paste()
        try:
            pyperclip.copy(text)
            time.sleep(_PASTE_SETUP_DELAY)
            keyboard.send("ctrl+v")
            time.sleep(_PASTE_RESTORE_DELAY)
        except Exception as e:
            log.error("[ERROR] 텍스트 입력 실패: %s", e)
        finally:
            pyperclip.copy(previous)

    def toggle(self) -> None:
        if not self.recording:
            self._start()
        else:
            audio_data = self._stop()
            if audio_data is not None:
                text = self._transcribe(audio_data)
                if text:
                    self._inject(text)


def main() -> None:
    parser = argparse.ArgumentParser(description="Voice input daemon for Claude Code")
    parser.add_argument("--hotkey", default="ctrl+shift+space", help="토글 단축키 (기본: ctrl+shift+space)")
    parser.add_argument("--lang", default="ko-KR", help="전사 언어 (기본: ko-KR)")
    args = parser.parse_args()

    stop_event = threading.Event()
    tray = pystray.Icon(
        name="voice_input",
        icon=_ICON_IDLE,
        title=_TITLE_IDLE,
        menu=pystray.Menu(
            pystray.MenuItem("종료", lambda icon, item: (stop_event.set(), icon.stop()))
        ),
    )
    recorder = VoiceRecorder(lang=args.lang, tray=tray)

    def setup(icon: pystray.Icon) -> None:
        icon.visible = True
        try:
            with open(_STATE_PATH, "w", encoding="utf-8") as _f:
                _f.write("idle")
        except OSError:
            pass
        hotkey_handle = keyboard.add_hotkey(args.hotkey, recorder.toggle, suppress=False)
        log.info("준비 완료. 단축키: %s  언어: %s", args.hotkey, args.lang)
        log.info("종료: 트레이 아이콘 우클릭 → 종료  또는  Ctrl+C")
        stop_event.wait()
        keyboard.remove_hotkey(hotkey_handle)
        try:
            import os as _os
            _os.unlink(_STATE_PATH)
        except OSError:
            pass

    # pystray.run()은 메인 스레드에서 실행해야 함 — Win32 메시지 루프 요구사항.
    try:
        tray.run(setup=setup)
    except KeyboardInterrupt:
        stop_event.set()
        log.info("[Voice Input] 종료.")
    except Exception as e:
        log.exception("치명적 오류: %s", e)
        raise


if __name__ == "__main__":
    main()
