function frame = simulateHumanRadarFrame(cfg, scenario)
%SIMULATEHUMANRADARFRAME Generate one synthetic FMCW radar frame.

rng(scenario.seed);

radar = cfg.radar;
scene = cfg.scene;

c = physconst("LightSpeed");
slopeHzPerS = radar.bandwidthHz / radar.chirpDurationS;
t = (0:radar.numSamples - 1).' / radar.sampleRateHz;

bodyZ = linspace(0.03, scenario.heightM, 34).';
baseAmp = 0.50 + 0.40 * exp(-((bodyZ - 0.56 * scenario.heightM) / (0.26 * scenario.heightM)).^2);
edgeBoost = 0.32 * exp(-((bodyZ - 0.05) / 0.05).^2) + ...
    0.30 * exp(-((bodyZ - scenario.heightM) / 0.05).^2);
bodyAmp = baseAmp + edgeBoost;
bodyX = scenario.rangeM + (bodyZ - 0.9) * tand(scenario.tiltDeg);

humanScatterers = [bodyX, bodyZ, bodyAmp];
clutterScatterers = scene.clutterPoints;

measurement = synthesizeFrame(humanScatterers, radar, t, slopeHzPerS, c) + ...
    synthesizeFrame(clutterScatterers, radar, t, slopeHzPerS, c);
background = synthesizeFrame(clutterScatterers, radar, t, slopeHzPerS, c);

measurement = measurement + scene.measurementNoiseAmp / sqrt(2) * ...
    (randn(size(measurement)) + 1i * randn(size(measurement)));
background = background + scene.backgroundNoiseAmp / sqrt(2) * ...
    (randn(size(background)) + 1i * randn(size(background)));

frame = struct();
frame.label = scenario.label;
frame.measurement = measurement;
frame.background = background;
frame.truth = struct( ...
    "heightM", scenario.heightM, ...
    "bottomM", 0.0, ...
    "topM", scenario.heightM, ...
    "bodyCenterXM", median(bodyX), ...
    "rangeM", scenario.rangeM, ...
    "tiltDeg", scenario.tiltDeg);
frame.scatterers = struct( ...
    "human", humanScatterers, ...
    "clutter", clutterScatterers);
end

function frame = synthesizeFrame(scatterers, radar, t, slopeHzPerS, c)
numSamples = radar.numSamples;
numRx = radar.numVirtualRx;
frame = zeros(numSamples, numRx);

for idx = 1:size(scatterers, 1)
    xM = scatterers(idx, 1);
    zM = scatterers(idx, 2);
    amplitude = scatterers(idx, 3);

    slantRangeM = hypot(xM, zM - radar.radarHeightM);
    elevationRad = atan2(zM - radar.radarHeightM, xM);
    beatHz = 2 * slopeHzPerS * slantRangeM / c;

    elementIdx = 0:(numRx - 1);
    spatialPhase = exp(1i * 2 * pi * elementIdx * radar.elementSpacingM * ...
        sin(elevationRad) / radar.lambdaM);
    timePhase = exp(1i * (2 * pi * beatHz * t + 4 * pi * slantRangeM / radar.lambdaM));

    frame = frame + amplitude * timePhase * spatialPhase;
end
end
