function test_converter_gaps(sessionDir, baseName)
% Regression test for lost-packet detection in translateNinja2022Bytesv3_BZ20230817_NN24.
% Cuts known numbers of packets out of a real .bin and checks that the parser reports exactly that many lost
% states, keeps the timeline intact (same number of frames as the uncut file) and fills the gap with NaN.
%
% usage: test_converter_gaps('/path/to/session', 'ninjaNIRS2024_2026-11-16-12-55-01')
% The folder must contain <baseName>.bin and <baseName>_stateMap.mat. Nothing is written.

m = load(fullfile(sessionDir, [baseName '_stateMap.mat']));
di = m.devInfo; srcram = m.stateMap;
fid = fopen(fullfile(sessionDir, [baseName '.bin'])); raw = fread(fid, 'uint8'); fclose(fid);

N_STATES = find(srcram(1,:,32)==1, 1, 'first');
NDB = di.N_DETECTOR_BOARDS;
if isfield(di,'N_IMU_BOARDS'), NIMU = di.N_IMU_BOARDS; else, NIMU = 0; end
acc = di.acc_active; aux = di.aux_active;
pkg = 1 + 2 + 8 + (NDB+NIMU)*28 + 18*acc;          % packet length (see the parser)
p0 = find(raw==254 & [raw(pkg:end); zeros(pkg-1,1)]==0, 1);   % first packet start
nDet = 8*NDB;

cut = @(k0, n) raw([1:(p0-1+(k0-1)*pkg), (p0-1+(k0-1+n)*pkg+1):numel(raw)]);
k0 = 10*N_STATES + 5;                              % cut starts in the middle of a frame

[rows0, nan0, lost0] = run(raw);
check(lost0 == 0 && nan0 == 0, 'uncut file: no lost states and no NaNs');

cases = [5, N_STATES, 3*N_STATES + 2, 3*N_STATES, 1, 2*N_STATES + 40];
for n = cases
    [rows, nNaN, lost, usedCounter] = run(cut(k0, n));
    check(usedCounter,                  sprintf('%4d packets removed: packet counter used', n));
    check(lost == n,                    sprintf('%4d packets removed: reported %d lost states', n, lost));
    check(rows == rows0,                sprintf('%4d packets removed: timeline keeps %d frames (got %d)', n, rows0, rows));
    check(nNaN == n*nDet,               sprintf('%4d packets removed: %d NaN samples (expected %d)', n, nNaN, n*nDet));
end
disp('ALL PASSED')

    function [rows, nNaN, lost, usedCounter] = run(r)
        [B, ~, ~, ~, ~, ~, info] = translateNinja2022Bytesv3_BZ20230817_NN24(r, srcram, NDB, NIMU, acc, aux);
        rows = size(B,1); nNaN = sum(isnan(B(:))); lost = info.lostStates; usedCounter = info.counterUsed;
    end
end

function check(ok, msg)
if ok, fprintf('PASS  %s\n', msg); else, error('FAIL  %s', msg); end
end
