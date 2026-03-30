function frame = loadRadarInput(cfg, scenario)
%LOADRADARINPUT Input abstraction for synthetic or real radar frames.

inputMode = lower(string(cfg.inputMode));

switch inputMode
    case "synthetic"
        frame = simulateHumanRadarFrame(cfg, scenario);
    otherwise
        error([ ...
            "Real radar input is not connected in this demo. " ...
            "Replace loadRadarInput.m so it returns the same frame fields " ...
            "(measurement, background, truth, scatterers)."]);
end
end
