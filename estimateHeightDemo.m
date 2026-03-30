function result = estimateHeightDemo(cfg, frame)
%ESTIMATEHEIGHTDEMO Estimate human height from one synthetic radar frame.

radar = cfg.radar;
proc = cfg.processing;
c = physconst("LightSpeed");
slopeHzPerS = radar.bandwidthHz / radar.chirpDurationS;

signal = frame.measurement - frame.background;

window = hann(radar.numSamples, "periodic");
rangeFft = fft(signal .* window, radar.numRangeFft, 1);
freqAxisHz = (0:radar.numRangeFft - 1).' / radar.numRangeFft * radar.sampleRateHz;
rangeAxisM = c * freqAxisHz / (2 * slopeHzPerS);

rangeMask = rangeAxisM >= proc.rangeLimitsM(1) & rangeAxisM <= proc.rangeLimitsM(2);
rangeFft = rangeFft(rangeMask, :);
rangeAxisM = rangeAxisM(rangeMask);

rangePower = sum(abs(rangeFft).^2, 2);
[~, peakIdx] = max(rangePower);
roi = max(1, peakIdx - proc.rangeRoiHalfWidthBins): ...
    min(numel(rangeAxisM), peakIdx + proc.rangeRoiHalfWidthBins);
rangeRoi = rangeFft(roi, :);

angleGridDeg = proc.angleGridDeg;
angleGridRad = deg2rad(angleGridDeg);
elementIdx = (0:radar.numVirtualRx - 1).';
steering = exp(1i * 2 * pi * elementIdx * radar.elementSpacingM * ...
    sin(angleGridRad) / radar.lambdaM);

rangeAnglePower = abs(rangeRoi * conj(steering)).^2;
rangeAnglePower = rangeAnglePower / max(rangeAnglePower(:) + eps);

[rangeIdx, angleIdx] = find(rangeAnglePower > proc.detectionThreshold);
weights = rangeAnglePower(rangeAnglePower > proc.detectionThreshold);
slantRange = rangeAxisM(roi(rangeIdx));
elevationRad = angleGridRad(angleIdx).';

xPointsM = slantRange .* cos(elevationRad);
zPointsM = radar.radarHeightM + slantRange .* sin(elevationRad);

strongMask = weights > proc.strongPointThreshold;
if any(strongMask)
    xCenterM = median(xPointsM(strongMask));
else
    xCenterM = sum(weights .* xPointsM) / sum(weights);
end

clusterMask = abs(xPointsM - xCenterM) < proc.targetHalfWidthM & ...
    zPointsM >= proc.zLimitsM(1) & zPointsM <= proc.zLimitsM(2);

clusterX = xPointsM(clusterMask);
clusterZ = zPointsM(clusterMask);
clusterW = weights(clusterMask);

zBounds = weightedPercentile(clusterZ, clusterW, proc.zPercentiles);
zBottomM = zBounds(1);
zTopM = zBounds(2);

xImageEdgesM = proc.xImageEdgesM;
zImageEdgesM = proc.zImageEdgesM;
[xzImage, xCentersM, zCentersM] = binPowerImage(clusterX, clusterZ, clusterW, xImageEdgesM, zImageEdgesM);

absoluteErrorM = abs((zTopM - zBottomM) - frame.truth.heightM);
clusterPowerRatio = sum(clusterW) / sum(weights);
confidence = min(0.99, 0.45 + 0.5 * clusterPowerRatio);

result = struct();
result.label = frame.label;
result.trueHeightM = frame.truth.heightM;
result.estimatedHeightM = zTopM - zBottomM;
result.absoluteErrorM = absoluteErrorM;
result.pass = absoluteErrorM <= cfg.acceptance.maxAbsErrorM;
result.confidence = confidence;
result.rangeAxisM = rangeAxisM;
result.rangePowerDb = toDb(rangePower / max(rangePower + eps));
result.rangeRoiAxisM = rangeAxisM(roi);
result.angleGridDeg = angleGridDeg;
result.rangeAnglePowerDb = toDb(rangeAnglePower + eps);
result.detectedPoints = [clusterX, clusterZ, clusterW];
result.xCenterM = xCenterM;
result.zBottomM = zBottomM;
result.zTopM = zTopM;
result.truth = frame.truth;
result.scatterers = frame.scatterers;
result.xImageM = xCentersM;
result.zImageM = zCentersM;
result.xzImageDb = toDb(xzImage + eps);
end

function bounds = weightedPercentile(samples, weights, probs)
samples = samples(:);
weights = weights(:);
probs = probs(:);

[samples, order] = sort(samples);
weights = weights(order);
weights = weights / sum(weights);
cdf = cumsum(weights);

bounds = zeros(size(probs));
for idx = 1:numel(probs)
    bounds(idx) = samples(find(cdf >= probs(idx), 1, "first"));
end
end

function [imagePower, xCentersM, zCentersM] = binPowerImage(xPointsM, zPointsM, weights, xEdgesM, zEdgesM)
xIdx = discretize(xPointsM, xEdgesM);
zIdx = discretize(zPointsM, zEdgesM);
valid = ~isnan(xIdx) & ~isnan(zIdx);

imagePower = accumarray([zIdx(valid), xIdx(valid)], weights(valid), ...
    [numel(zEdgesM) - 1, numel(xEdgesM) - 1], @sum, 0);
smoothKernel = [1, 2, 1; 2, 4, 2; 1, 2, 1] / 16;
imagePower = conv2(imagePower, smoothKernel, "same");

xCentersM = xEdgesM(1:end-1) + diff(xEdgesM) / 2;
zCentersM = zEdgesM(1:end-1) + diff(zEdgesM) / 2;
end

function y = toDb(x)
y = 10 * log10(max(x, eps));
end
