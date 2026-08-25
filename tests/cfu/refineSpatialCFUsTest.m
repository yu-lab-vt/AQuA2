classdef refineSpatialCFUsTest < matlab.unittest.TestCase
    %REFINESPATIALCFUSTEST Unit tests for connected CFU spatial refinement.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            rootFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(rootFolder, 'src'), IncludingSubfolders=true));
        end
    end

    methods (Test)
        function testWeakBridgeSplitsTwoRegions(testCase)
            [evtIhw, weightedIhw, maxCounts, sz] = refineSpatialCFUsTest.bridgeFixture();

            [regions, lists, parentIds] = cfu.refineSpatialCFUs( ...
                {[1 2]}, evtIhw, weightedIhw, maxCounts, sz, 1, 23);

            testCase.verifyEqual(numel(lists), 2);
            testCase.verifyEqual(sort(cellfun(@numel, lists)), [1; 1]);
            testCase.verifyEqual(parentIds, [23; 23]);
            testCase.verifyEqual(cellfun(@(x) bwconncomp(x > 0.1, 8).NumObjects, regions), [1; 1]);
        end

        function testCFUMinMeasureAppliesSpatialRefinement(testCase)
            [evtIhw, weightedIhw, maxCounts, sz] = refineSpatialCFUsTest.bridgeFixture();
            cfuPre = struct('s_t0', [1 2 1], 'weightedIhw', {weightedIhw}, ...
                'maxCounts', maxCounts, 'evtIhw', {evtIhw});

            [regions, lists, ~, ~, parentIds] = cfu.CFU_minMeasure( ...
                cfuPre, true(2,1), [], sz, 0.5, 1, false);

            testCase.verifyEqual(numel(lists), 2);
            testCase.verifyEqual(parentIds, [1; 1]);
            testCase.verifyEqual(cellfun(@(x) bwconncomp(x > 0.1, 8).NumObjects, regions), [1; 1]);
        end

        function testSmallSatelliteIsRemoved(testCase)
            [evtIhw, weightedIhw, maxCounts, sz, satellitePixels] = ...
                refineSpatialCFUsTest.satelliteFixture();

            [regions, lists] = cfu.refineSpatialCFUs( ...
                {1}, evtIhw, weightedIhw, maxCounts, sz, 1);

            testCase.verifyEqual(lists, {1});
            testCase.verifyFalse(any(regions{1}(satellitePixels) > 0));
            testCase.verifyEqual(bwconncomp(regions{1} > 0.1, 8).NumObjects, 1);
        end

        function testCoherentRegionRemainsOneCFU(testCase)
            [evtIhw, weightedIhw, maxCounts, sz] = refineSpatialCFUsTest.coherentFixture();

            [regions, lists, parentIds] = cfu.refineSpatialCFUs( ...
                {[1 2]}, evtIhw, weightedIhw, maxCounts, sz, 1);

            testCase.verifyEqual(lists, {[1 2]});
            testCase.verifyEqual(parentIds, 1);
            testCase.verifyEqual(bwconncomp(regions{1} > 0.1, 8).NumObjects, 1);
            testCase.verifyTrue(all(regions{1}(regions{1} > 0) > 0.1));
        end

        function testDurationWeightsKeepLowEvidenceBoundaryOut(testCase)
            [evtIhw, weightedIhw, maxCounts, sz, boundaryPixel, corePixel] = ...
                refineSpatialCFUsTest.weightedBoundaryFixture();

            [regions, lists] = cfu.refineSpatialCFUs( ...
                {1}, evtIhw, weightedIhw, maxCounts, sz, 1);

            testCase.verifyEqual(lists, {1});
            testCase.verifyEqual(regions{1}(boundaryPixel), single(0));
            testCase.verifyGreaterThan(regions{1}(corePixel), 0.1);
        end
    end

    methods (Static, Access = private)
        function [evtIhw, weightedIhw, maxCounts, sz] = bridgeFixture()
            sz = [24 24 1 1];
            leftCore = refineSpatialCFUsTest.rectanglePixels(sz, 4:10, 3:8);
            rightCore = refineSpatialCFUsTest.rectanglePixels(sz, 4:10, 17:22);
            bridge = refineSpatialCFUsTest.rectanglePixels(sz, 7, 9:16);
            evtIhw = {unique([leftCore; bridge]), unique([rightCore; bridge])};
            weightedIhw = {ones(numel(evtIhw{1}),1), ones(numel(evtIhw{2}),1)};
            weightedIhw{1}(ismember(evtIhw{1}, bridge)) = 0.09;
            weightedIhw{2}(ismember(evtIhw{2}, bridge)) = 0.09;
            maxCounts = [1; 1];
        end

        function [evtIhw, weightedIhw, maxCounts, sz, satellitePixels] = satelliteFixture()
            sz = [24 24 1 1];
            corePixels = refineSpatialCFUsTest.rectanglePixels(sz, 4:10, 4:10);
            satellitePixels = refineSpatialCFUsTest.rectanglePixels(sz, 18:19, 18:19);
            evtIhw = {unique([corePixels; satellitePixels])};
            weightedIhw = {ones(numel(evtIhw{1}),1)};
            maxCounts = 1;
        end

        function [evtIhw, weightedIhw, maxCounts, sz] = coherentFixture()
            sz = [24 24 1 1];
            first = refineSpatialCFUsTest.rectanglePixels(sz, 5:13, 5:13);
            second = refineSpatialCFUsTest.rectanglePixels(sz, 7:15, 7:15);
            evtIhw = {first, second};
            weightedIhw = {ones(numel(first),1), ones(numel(second),1)};
            maxCounts = [1; 1];
        end

        function [evtIhw, weightedIhw, maxCounts, sz, boundaryPixel, corePixel] = weightedBoundaryFixture()
            sz = [24 24 1 1];
            outerPixels = refineSpatialCFUsTest.rectanglePixels(sz, 3:15, 3:15);
            corePixels = refineSpatialCFUsTest.rectanglePixels(sz, 6:12, 6:12);
            evtIhw = {outerPixels};
            weightedIhw = {0.05 * ones(numel(outerPixels),1)};
            weightedIhw{1}(ismember(outerPixels, corePixels)) = 1;
            maxCounts = 1;
            boundaryPixel = sub2ind(sz(1:3), 3, 3, 1);
            corePixel = sub2ind(sz(1:3), 9, 9, 1);
        end

        function pixels = rectanglePixels(sz, rows, columns)
            [rowGrid, columnGrid] = ndgrid(rows, columns);
            pixels = sub2ind(sz(1:3), rowGrid(:), columnGrid(:), ones(numel(rowGrid), 1));
        end
    end
end
