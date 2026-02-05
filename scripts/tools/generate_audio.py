import math
import os
import random
import wave

SAMPLE_RATE = 44100


def _write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += int(v * 32767).to_bytes(2, byteorder="little", signed=True)
        wf.writeframes(frames)


def _env_exp(t, decay):
    return math.exp(-t * decay)


def _gen_click(duration=0.06):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        noise = random.uniform(-1.0, 1.0)
        env = _env_exp(t, 40.0)
        samples.append(noise * env * 0.6)
    return samples


def _gen_relay(duration=0.12):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = _env_exp(t, 25.0)
        tone = math.sin(2 * math.pi * 180 * t) * 0.4
        tone += math.sin(2 * math.pi * 90 * t) * 0.25
        noise = random.uniform(-0.2, 0.2)
        samples.append((tone + noise) * env)
    return samples


def _gen_buzzer(duration=0.45):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = 0.9 if t < duration - 0.05 else max(0.0, 1.0 - (t - (duration - 0.05)) / 0.05)
        tone = math.sin(2 * math.pi * 70 * t) * 0.6
        noise = random.uniform(-0.1, 0.1)
        samples.append((tone + noise) * env)
    return samples


def main():
    random.seed(7)
    base = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
    _write_wav(os.path.join(base, "click.wav"), _gen_click())
    _write_wav(os.path.join(base, "relay.wav"), _gen_relay())
    _write_wav(os.path.join(base, "buzzer.wav"), _gen_buzzer())


if __name__ == "__main__":
    main()
