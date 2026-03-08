%% Fine sweep with multiple seeds for reliable yield estimate
clear all;

B = 12; Bt = 3; Bb = B - Bt;
dnlspec = 0.5; inlspec = 0.5;
r = 100; ku = 6e-2;
nseeds = 10;

Aunit_values = 110:10:180;

fprintf('%-10s', 'Aunit');
for s=1:nseeds, fprintf('seed%-3d ', s); end
fprintf('  avg_yield%%\n');
fprintf('%s\n', repmat('-', 1, 10 + nseeds*8 + 12));

bsm = zeros(2^Bb, Bb);
for i=1:2^Bb
    for j=1:Bb
        if mod(floor((i-1)/2^(j-1)), 2), bsm(i, end-j+1) = 1; end
    end
end

for aidx = 1:length(Aunit_values)
    Aunit = Aunit_values(aidx);
    sigma = ku/sqrt(Aunit);
    yields = zeros(1, nseeds);

    for seed = 1:nseeds
        rng(seed);
        u = sigma*randn(r, 2^B-1) + 1;
        u_bw = u(:, 1:2^Bb-1);
        u_th = u(:, 2^Bb:end);

        code = zeros(r, 2^B);
        for m=1:r
            bw = zeros(Bb,1);
            for i=1:Bb
                bw(end-i+1) = sum(u_bw(m, 2^(i-1):2^i-1));
            end
            bw_codes = bsm*bw;
            for i=1:2^B
                lsb = bw_codes(mod(i-1, 2^Bb)+1);
                msbs_on = floor((i-1)/2^Bb);
                if msbs_on, msb = sum(u_th(m, 1:2^Bb*msbs_on));
                else, msb = 0; end
                code(m, i) = lsb + msb;
            end
        end

        bad_total = 0;
        for m=1:r
            avg_width = (code(m, end)-code(m, 1))/(2^B-1);
            inl_m = (code(m,:) - avg_width*(0:2^B-1)) ./ avg_width;
            dnl_m = diff(code(m,:)) ./ avg_width - 1;
            if any(abs(inl_m) > inlspec) || any(abs(dnl_m) > dnlspec)
                bad_total = bad_total + 1;
            end
        end
        yields(seed) = (r - bad_total)/r * 100;
    end

    fprintf('%-10.0f', Aunit);
    for s=1:nseeds, fprintf('%-8.0f', yields(s)); end
    fprintf('  %.1f\n', mean(yields));
end
