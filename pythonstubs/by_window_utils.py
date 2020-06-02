# Statistically and Math libraries are not supported in MicroPython for ESP32


def mean(values):
    sum = 0
    for value in values:
        sum = sum + value
    return sum / len(values)


def median(values):
    values = sorted(values)
    length = len(values)
    index = length // 2
    if length % 2 == 0:
        return (values[index - 1] + values[index]) / 2
    else:
        return values[index]


def var(values):
    return __ss(values) / (len(values) - 1)


def stdev(values):
    return sqrt(var(values))


def sqrt(value):
    low = 0
    high = value
    for i in range(1000):
        mid = (low + high) / 2
        if mid * mid == value:
            return mid
        if mid * mid > value:
            high = mid
        else:
            low = mid
    return mid


def minimum(values):
    return min(values)


def maximum(values):
    return max(values)


def __ss(values):
    avg = mean(values)
    total1 = 0
    total2 = 0
    for value in values:
        total1 += (value - avg) ** 2
        total2 += (value - avg)
    return total1 - (total2 ** 2 / len(values))
