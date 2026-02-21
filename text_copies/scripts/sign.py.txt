import wave
import struct
import math
import random

def generate_wav(filename, duration, volume=0.5, func=None):
    # Параметры звука
    sample_rate = 44100.0  # Частота дискретизации (Гц)
    num_samples = int(duration * sample_rate)
    
    # Открываем файл на запись
    with wave.open(filename, 'w') as wav_file:
        # Устанавливаем параметры: 1 канал (моно), 2 байта на семпл (16 бит), частота
        wav_file.setparams((1, 2, int(sample_rate), num_samples, 'NONE', 'not compressed'))
        
        for i in range(num_samples):
            t = i / sample_rate
            # Генерируем значение амплитуды через переданную функцию
            value = func(t, duration, volume)
            
            # Ограничиваем амплитуду и переводим в 16-битное целое число
            sample = int(max(-1, min(1, value)) * 32767)
            wav_file.writeframes(struct.pack('<h', sample))

# 1. Механический клик (короткий импульс с затуханием)
def click_sound(t, duration, volume):
    # Высокочастотный синус с очень быстрым экспоненциальным затуханием
    freq = 1500
    decay = math.exp(-t * 100)
    return volume * math.sin(2 * math.pi * freq * t) * decay

# 2. Звук реле (двойной щелчок с небольшим шумом)
def relay_sound(t, duration, volume):
    # Два коротких щелчка
    click1 = math.exp(-t * 80) * math.sin(2 * math.pi * 1200 * t)
    click2 = 0
    if t > 0.05:
        click2 = math.exp(-(t-0.05) * 80) * math.sin(2 * math.pi * 1000 * (t-0.05))
    
    # Добавляем немного механического шума
    noise = (random.random() * 2 - 1) * math.exp(-t * 40) * 0.2
    return volume * (click1 + click2 + noise)

# 3. Звук ошибки (низкочастотный "баззер")
def error_sound(t, duration, volume):
    # Прямоугольная волна (дает характерный "игровой" звук ошибки)
    freq = 120
    if math.sin(2 * math.pi * freq * t) > 0:
        return volume * 0.5
    else:
        return -volume * 0.5

# Генерация файлов
print("Генерация звуковых эффектов...")

# Краткий клик (0.05 сек)
generate_wav("click.wav", 0.05, volume=0.6, func=click_sound)

# Реле (0.15 сек)
generate_wav("relay.wav", 0.15, volume=0.5, func=relay_sound)

# Ошибка (0.3 сек)
generate_wav("error.wav", 0.3, volume=0.4, func=error_sound)

print("Готово! Файлы click.wav, relay.wav и error.wav созданы.")