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
            [evtIhw, sz] = refineSpatialCFUsTest.bridgeFixture();

            [regions, lists, parentIds] = cfu.refineSpatialCFUs({[1 2]}, evtIhw, sz, 1);

            testCase.verifyEqual(numel(lists), 2);
            testCase.verifyEqual(sort(cellfun(@numel, lists)), [1; 1]);
            testCase.verifyEqual(parentIds, [1; 1]);
            testCase.verifyEqual(cellfun(@(x) bwconncomp(x > 0.1, 8).NumObjects, regions), [1; 1]);
        end

        function testCFUMinMeasureAppliesSpatialRefinement(testCase)
            [evtIhw, sz] = refineSpatialCFUsTest.bridgeFixture();
            cfuPre = struct('s_t0', [1 2 1], 'weightedIhw', {evtIhw}, ...
                'maxCounts', [1; 1], 'evtIhw', {evtIhw});

            [regions, lists, ~, ~, parentIds] = cfu.CFU_minMeasure( ...
                cfuPre, true(2,1), [], sz, 0.5, 1, false);

            testCase.verifyEqual(numel(lists), 2);
            testCase.verifyEqual(parentIds, [1; 1]);
            testCase.verifyEqual(cellfun(@(x) bwconncomp(x > 0.1, 8).NumObjects, regions), [1; 1]);
        end

        function testSmallSatelliteIsRemoved(testCase)
            [evtIhw, sz, satellitePixels] = refineSpatialCFUsTest.satelliteFixture();

            [regions, lists] = cfu.refineSpatialCFUs({1}, evtIhw, sz, 1);

            testCase.verifyEqual(lists, {1});
            testCase.verifyFalse(any(regions{1}(satellitePixels) > 0));
            testCase.verifyEqual(bwconncomp(regions{1} > 0.1, 8).NumObjects, 1);
        end

        function testCoherentRegionRemainsOneCFU(testCase)
            [evtIhw, sz] = refineSpatialCFUsTest.coherentFixture();

            [regions, lists, parentIds] = cfu.refineSpatialCFUs({[1 2]}, evtIhw, sz, 1);

            testCase.verifyEqual(lists, {[1 2]});
            testCase.verifyEqual(parentIds, 1);
            testCase.verifyEqual(bwconncomp(regions{1} > 0.1, 8).NumObjects, 1);
            testCase.verifyTrue(all(regions{1}(regions{1} > 0) > 0.1));
        end
    end

    methods (Static, Access = private)
        function [evtIhw, sz] = bridgeFixture()
            sz = [24 24 1 1];
            leftCore = refineSpatialCFUsTest.rectanglePixels(sz, 4:10, 3:8);
            rightCore = refineSpatialCFUsTest.rectanglePixels(sz, 4:10, 17:22);
            bridge = refineSpatialCFUsTest.rectanglePixels(sz, 7, 9:16);
            evtIhw = {unique([leftCore; bridge]), unique([rightCore; bridge])};
        end

        function [evtIhw, sz, satellitePixels] = satelliteFixture()
            sz = [24 24 1 1];
            corePixels = refineSpatialCFUsTest.rectanglePixels(sz, 4:10, 4:10);
            satellitePixels = refineSpatialCFUsTest.rectanglePixels(sz, 18:19, 18:19);
            evtIhw = {unique([corePixels; satellitePixels])};
        end

        function [evtIhw, sz] = coherentFixture()
            sz = [24 24 1 1];
            first = refineSpatialCFUsTest.rectanglePixels(sz, 5:13, 5:13);
            second = refineSpatialCFUsTest.rectanglePixels(sz, 7:15, 7:15);
            evtIhw = {first, second};
        end

        function pixels = rectanglePixels(sz, rows, columns)
            [rowGrid, columnGrid] = ndgrid(rows, columns);
            pixels = sub2ind(sz(1:3), rowGrid(:), columnGrid(:), ones(numel(rowGrid), 1));
        end
    end
end
