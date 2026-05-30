"""Generate subtle, premium alarm tone WAV files for Habit Up."""
import struct, math, os

SAMPLE_RATE = 44100

def write_wav(path, samples):
    max_val = max(abs(s) for s in samples) or 1
    int_samples = [max(-32768, min(32767, int((s/max_val)*32767*0.8))) for s in samples]
    with open(path, 'wb') as f:
        data_size = len(int_samples)*2
        f.write(b'RIFF' + struct.pack('<I',36+data_size) + b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<I',16) + struct.pack('<H',1) + struct.pack('<H',1))
        f.write(struct.pack('<I',SAMPLE_RATE) + struct.pack('<I',SAMPLE_RATE*2))
        f.write(struct.pack('<H',2) + struct.pack('<H',16))
        f.write(b'data' + struct.pack('<I',data_size))
        for s in int_samples:
            f.write(struct.pack('<h',s))

os.makedirs('assets/audio', exist_ok=True)

# 1. Chime — soft C5 (523Hz) with octave & third harmonics, 1.5s
n = int(SAMPLE_RATE * 1.5)
samples = []
for i in range(n):
    t = i / SAMPLE_RATE
    env = min(1.0, t / 0.05)
    if t > 0.8:
        env *= 1.0 - (t - 0.8) / 0.7
    v = math.sin(2*math.pi*523*t) * env
    v += math.sin(2*math.pi*1047*t) * 0.25 * env
    v += math.sin(2*math.pi*1569*t) * 0.10 * env
    samples.append(v)
write_wav('assets/audio/alarm_chime.wav', samples)
print(f'  chime.wav  — {os.path.getsize("assets/audio/alarm_chime.wav")} bytes')

# 2. Pulse — two short A4 (440Hz) pulses, 1.0s
n = int(SAMPLE_RATE * 1.0)
samples = []
for i in range(n):
    t = i / SAMPLE_RATE
    env = 0.0
    if t < 0.15:
        env = min(1.0, t/0.02) * max(0.0, 1.0 - (t-0.02)/0.13)
    elif 0.30 <= t < 0.45:
        env = min(1.0, (t-0.30)/0.02) * max(0.0, 1.0 - (t-0.32)/0.13)
    v = (math.sin(2*math.pi*440*t) + math.sin(2*math.pi*880*t)*0.3) * env
    samples.append(v)
write_wav('assets/audio/alarm_pulse.wav', samples)
print(f'  pulse.wav   — {os.path.getsize("assets/audio/alarm_pulse.wav")} bytes')

# 3. Notification — clear A5 (880Hz) tone, 0.5s
n = int(SAMPLE_RATE * 0.5)
samples = []
for i in range(n):
    t = i / SAMPLE_RATE
    env = min(1.0, t/0.01)
    if t > 0.35:
        env *= 1.0 - (t - 0.35) / 0.15
    v = (math.sin(2*math.pi*880*t) + math.sin(2*math.pi*1320*t)*0.2) * env
    samples.append(v)
write_wav('assets/audio/alarm_notification.wav', samples)
print(f'  notification.wav — {os.path.getsize("assets/audio/alarm_notification.wav")} bytes')

# 4. Bedtime — soft C4 (264Hz) with vibrato & harmonics, 2.5s
n = int(SAMPLE_RATE * 2.5)
samples = []
for i in range(n):
    t = i / SAMPLE_RATE
    env = min(1.0, t/0.1)
    if t > 1.5:
        env *= 1.0 - (t - 1.5) / 1.0
    v = math.sin(2*math.pi*264*t + math.sin(2*math.pi*4*t)*0.03) * env * 0.8
    v += math.sin(2*math.pi*396*t) * 0.35 * env
    v += math.sin(2*math.pi*528*t) * 0.15 * env
    samples.append(v)
write_wav('assets/audio/alarm_bedtime.wav', samples)
print(f'  bedtime.wav — {os.path.getsize("assets/audio/alarm_bedtime.wav")} bytes')

print('All 4 alarm audio assets generated successfully!')
