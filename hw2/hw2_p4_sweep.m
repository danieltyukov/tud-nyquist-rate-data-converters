%% Homework 2 - Problem 4(d): Sweep Aunit to find 95% yield
% Keeps Bt=3 fixed, varies Aunit
clear all;

B = 12;
Bt = 3;
Bb = B - Bt;
dnlspec = 0.5;
inlspec = 0.5;
r = 100;
ku = 6e-2;

% Sweep Aunit values (log-spaced from ~50 to ~400)
Aunit_values = [50, 75, 100, 120, 130, 140, 150, 160, 170, 180, 200, 220, 250, 300];

fprintf('%-10s %-10s %-10s %-10s %-10s %-10s\n', ...
    'Aunit', 'sigma_u', 'bad_INL', 'bad_DNL', 'bad_total', 'yield%');
fprintf('%s\n', repmat('-', 1, 60));

rng(42); % fix seed for reproducibility

for aidx = 1:length(Aunit_values)
    Aunit = Aunit_values(aidx);
    sigma = ku/sqrt(Aunit);

    u = sigma*randn(r, 2^B-1) + 1;
    u_bw = u(:, 1:2^Bb-1);
    u_th = u(:, 2^Bb:end);

    bsm = zeros(2^Bb, Bb);
    for i=1:2^Bb
        for j=1:Bb
            if mod(floor((i-1)/2^(j-1)), 2)
                bsm(i, end-j+1) = 1;
            end
        end
    end

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
            if msbs_on
                msb = sum(u_th(m, 1:2^Bb*msbs_on));
            else
                msb = 0;
            end
            code(m, i) = lsb + msb;
        end
    end

    % INL
    inl = zeros(r, 2^B);
    for m=1:r
        avg_width = (code(m, end)-code(m, 1))/(2^B-1);
        inl(m, :) = (code(m,:) - avg_width*(0:2^B-1)) ./ avg_width;
    end

    % DNL
    dnl = zeros(r, 2^B-1);
    for m=1:r
        avg_width = (code(m, end)-code(m, 1))/(2^B-1);
        dnl(m, :) = diff(code(m,:)) ./ avg_width - 1;
    end

    bad_inl = 0; bad_dnl = 0; bad_total = 0;
    for m=1:r
        fail_inl = any(abs(inl(m,:)) > inlspec);
        fail_dnl = any(abs(dnl(m,:)) > dnlspec);
        bad_inl = bad_inl + fail_inl;
        bad_dnl = bad_dnl + fail_dnl;
        bad_total = bad_total + (fail_inl || fail_dnl);
    end

    yield = (r - bad_total)/r * 100;
    fprintf('%-10.1f %-10.6f %-10d %-10d %-10d %-10.1f\n', ...
        Aunit, sigma, bad_inl, bad_dnl, bad_total, yield);
end
