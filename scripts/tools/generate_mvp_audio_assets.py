import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "audio"
SAMPLE_RATE = 44100


def clamp(value, lo=-1.0, hi=1.0):
    return max(lo, min(hi, value))


def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(0.001, max(abs(s) for s in samples))
    gain = 0.92 / peak
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        frames = bytearray()
        for sample in samples:
            frames.extend(struct.pack("<h", int(clamp(sample * gain) * 32767)))
        wav.writeframes(frames)


def envelope(t, attack, release, length):
    if t < attack:
        return t / max(attack, 0.0001)
    if t > length - release:
        return max(0.0, (length - t) / max(release, 0.0001))
    return 1.0


def noise_hit(length, base_freq, decay, seed, grit=0.45, tone=0.65):
    rng = random.Random(seed)
    count = int(length * SAMPLE_RATE)
    samples = []
    last = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * decay) * envelope(t, 0.002, 0.03, length)
        low = math.sin(t * base_freq * math.tau) * tone
        last = last * 0.78 + rng.uniform(-1.0, 1.0) * 0.22
        scrape = rng.uniform(-1.0, 1.0) * grit
        samples.append((low + last + scrape) * env)
    return samples


def player_footstep(seed, pitch=1.0):
    samples = noise_hit(0.18, 105.0 * pitch, 18.0, seed, 0.25, 0.55)
    scrape = noise_hit(0.11, 240.0 * pitch, 34.0, seed + 19, 0.15, 0.18)
    offset = int(0.055 * SAMPLE_RATE)
    for i, value in enumerate(scrape):
        j = i + offset
        if j < len(samples):
            samples[j] += value * 0.45
    return samples


def monster_footstep(seed):
    samples = noise_hit(0.28, 54.0, 12.0, seed, 0.38, 0.88)
    thump = noise_hit(0.16, 32.0, 18.0, seed + 7, 0.12, 1.0)
    for i, value in enumerate(thump):
        if i < len(samples):
            samples[i] += value * 0.8
    return samples


def breath_loop(seed):
    rng = random.Random(seed)
    length = 2.8
    count = int(length * SAMPLE_RATE)
    samples = []
    last = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        phase = (t / length) % 1.0
        inhale = math.sin(min(phase, 0.5) / 0.5 * math.pi) if phase < 0.5 else 0.0
        exhale = math.sin((phase - 0.5) / 0.5 * math.pi) if phase >= 0.5 else 0.0
        last = last * 0.985 + rng.uniform(-1.0, 1.0) * 0.015
        airy = last * (0.22 + inhale * 0.38 + exhale * 0.55)
        chest = math.sin(t * 88.0 * math.tau) * 0.025 * (inhale + exhale)
        samples.append(airy + chest)
    return samples


def monster_roar(seed):
    rng = random.Random(seed)
    length = 1.45
    count = int(length * SAMPLE_RATE)
    samples = []
    last = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        env = envelope(t, 0.045, 0.25, length)
        sweep = 92.0 - t * 28.0 + math.sin(t * 7.0) * 12.0
        tone = math.sin(t * sweep * math.tau)
        growl = math.sin(t * sweep * 0.51 * math.tau + math.sin(t * 17.0) * 2.1)
        last = last * 0.94 + rng.uniform(-1.0, 1.0) * 0.06
        samples.append((tone * 0.42 + growl * 0.48 + last * 0.36) * env)
    return samples


def monster_attack(seed):
    hit = noise_hit(0.42, 70.0, 10.0, seed, 0.55, 0.85)
    snarl = monster_roar(seed + 13)[: int(0.42 * SAMPLE_RATE)]
    return [hit[i] * 0.85 + snarl[i] * 0.35 for i in range(len(hit))]


def nightmare_sonar_call(seed):
    rng = random.Random(seed)
    length = 0.86
    count = int(length * SAMPLE_RATE)
    samples = []
    last = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        env = envelope(t, 0.012, 0.18, length)
        pulse = 0.0
        for pulse_time, pulse_freq in [(0.04, 1320.0), (0.18, 980.0), (0.34, 720.0)]:
            dt = t - pulse_time
            if dt >= 0.0:
                pulse_env = math.exp(-dt * 22.0)
                pulse += math.sin(dt * pulse_freq * math.tau) * pulse_env
        last = last * 0.965 + rng.uniform(-1.0, 1.0) * 0.035
        chest = math.sin(t * (58.0 + 12.0 * math.sin(t * 4.0)) * math.tau) * 0.26
        samples.append((pulse * 0.72 + chest + last * 0.24) * env)
    return samples


def locked_door_rattle(seed):
    rng = random.Random(seed)
    length = 0.62
    count = int(length * SAMPLE_RATE)
    samples = [0.0 for _ in range(count)]
    for hit_index, hit_time in enumerate([0.02, 0.12, 0.19, 0.36, 0.43]):
        hit = noise_hit(0.12, 180.0 + hit_index * 22.0, 31.0, seed + hit_index, 0.62, 0.45)
        start = int(hit_time * SAMPLE_RATE)
        for i, value in enumerate(hit):
            j = start + i
            if j < count:
                samples[j] += value * (0.85 + rng.random() * 0.25)
    return samples


def key_pickup():
    length = 0.42
    count = int(length * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = envelope(t, 0.005, 0.18, length)
        tone = math.sin(t * 880.0 * math.tau) * 0.45 + math.sin(t * 1320.0 * math.tau) * 0.25
        samples.append(tone * env)
    return samples


def victory_open():
    length = 0.9
    count = int(length * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = envelope(t, 0.02, 0.25, length)
        tone = math.sin(t * 190.0 * math.tau) * 0.35
        tone += math.sin(t * (260.0 + 60.0 * t) * math.tau) * 0.24
        samples.append(tone * env)
    return samples


def main():
    write_wav(OUT / "player_footstep_01.wav", player_footstep(100, 1.0))
    write_wav(OUT / "player_footstep_02.wav", player_footstep(200, 1.08))
    write_wav(OUT / "player_breath_loop.wav", breath_loop(300))
    write_wav(OUT / "monster_footstep_01.wav", monster_footstep(400))
    write_wav(OUT / "monster_footstep_02.wav", monster_footstep(500))
    write_wav(OUT / "monster_roar.wav", monster_roar(600))
    write_wav(OUT / "monster_attack.wav", monster_attack(700))
    write_wav(OUT / "nightmare_sonar_call.wav", nightmare_sonar_call(750))
    write_wav(OUT / "locked_door_rattle.wav", locked_door_rattle(800))
    write_wav(OUT / "key_pickup.wav", key_pickup())
    write_wav(OUT / "exit_door_unlock_open.wav", victory_open())
    print("GENERATE_MVP_AUDIO_ASSETS PASS path=%s count=11" % OUT)


if __name__ == "__main__":
    main()
