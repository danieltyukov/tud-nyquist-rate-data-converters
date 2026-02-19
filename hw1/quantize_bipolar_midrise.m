function output = quantize_bipolar_midrise(input, FSR, B)
    LSB = FSR/2^B;
    output = round((input - LSB/2)/LSB)*LSB + LSB/2;
    output = min(output, FSR/2 - LSB/2);
    output = max(output, -FSR/2 + LSB/2);
end

