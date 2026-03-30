function plotHeightDemoResults(~, result)
%PLOTHEIGHTDEMORESULTS Visualize the nominal height-estimation case.

figure("Color", "w", "Name", "mmWave Human Height Demo", "Position", [120, 80, 1300, 820]);
tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile;
plot(result.rangeAxisM, result.rangePowerDb, "LineWidth", 1.5, "Color", [0.10, 0.35, 0.75]);
hold on;
xline(result.truth.rangeM, "--", "True center range", "Color", [0.20, 0.60, 0.20], "LineWidth", 1.2);
xlabel("Slant range (m)");
ylabel("Normalized power (dB)");
title(sprintf("%s: Range Profile", result.label));
grid on;

nexttile;
imagesc(result.angleGridDeg, result.rangeRoiAxisM, result.rangeAnglePowerDb);
axis xy;
colormap(turbo(256));
colorbar;
xlabel("Elevation angle (deg)");
ylabel("Slant range (m)");
title("Range-Angle Power Map");

nexttile;
imagesc(result.xImageM, result.zImageM, result.xzImageDb);
axis xy;
hold on;
plot(result.scatterers.human(:, 1), result.scatterers.human(:, 2), "wo", ...
    "MarkerSize", 3.5, "LineWidth", 0.9);
plot([result.truth.bodyCenterXM, result.truth.bodyCenterXM], ...
    [result.truth.bottomM, result.truth.topM], "--", ...
    "Color", [0.15, 0.85, 0.25], "LineWidth", 2.0);
plot([result.xCenterM, result.xCenterM], [result.zBottomM, result.zTopM], "-", ...
    "Color", [1.00, 0.55, 0.10], "LineWidth", 2.5);
scatter(result.xCenterM, result.zBottomM, 55, [1.00, 0.55, 0.10], "filled");
scatter(result.xCenterM, result.zTopM, 55, [1.00, 0.55, 0.10], "filled");
xlabel("Downrange x (m)");
ylabel("Height z (m)");
title("x-z Power Projection");
legend({"Human scatterers", "True height", "Estimated height"}, "Location", "northeast");
colorbar;
colormap(turbo(256));

nexttile;
axis off;
text(0.02, 0.88, sprintf("Scenario: %s", result.label), "FontSize", 13, "FontWeight", "bold");
text(0.02, 0.73, sprintf("True height:      %.3f m", result.trueHeightM), "FontSize", 12);
text(0.02, 0.60, sprintf("Estimated height: %.3f m", result.estimatedHeightM), "FontSize", 12);
text(0.02, 0.47, sprintf("Absolute error:   %.3f m", result.absoluteErrorM), "FontSize", 12);
text(0.02, 0.34, sprintf("Confidence:       %.2f", result.confidence), "FontSize", 12);
text(0.02, 0.21, sprintf("Pass:             %s", string(result.pass)), "FontSize", 12);
text(0.02, 0.06, "Geometry: radar at x = 0 m, z = 1.0 m; standing single target; static indoor scene.", ...
    "FontSize", 11);
title("Summary");
end
