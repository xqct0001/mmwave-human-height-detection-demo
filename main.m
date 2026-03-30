clear;
clc;
close all;

cfg = configRadarScene();
numCases = numel(cfg.demoScenarios);
firstFrame = loadRadarInput(cfg, cfg.demoScenarios(1));
firstResult = estimateHeightDemo(cfg, firstFrame);
results = repmat(firstResult, numCases, 1);
results(1) = firstResult;

fprintf("mmWave radar human-height demo\n");
fprintf("Input mode: %s\n\n", cfg.inputMode);

for caseIdx = 2:numCases
    frame = loadRadarInput(cfg, cfg.demoScenarios(caseIdx));
    results(caseIdx) = estimateHeightDemo(cfg, frame);
end

summaryTable = table( ...
    string({results.label}).', ...
    [results.trueHeightM].', ...
    [results.estimatedHeightM].', ...
    [results.absoluteErrorM].', ...
    [results.confidence].', ...
    [results.pass].', ...
    'VariableNames', ["Scenario", "TrueHeightM", "EstimatedHeightM", "AbsErrorM", "Confidence", "Pass"]);

disp(summaryTable);

fprintf("Acceptance rule: |error| <= %.0f cm\n", cfg.acceptance.maxAbsErrorM * 100);
fprintf("Pass count: %d / %d\n", nnz([results.pass]), numCases);

nominalIdx = find([cfg.demoScenarios.isNominal], 1, "first");
if isempty(nominalIdx)
    nominalIdx = 1;
end

plotHeightDemoResults(cfg, results(nominalIdx));
