classdef mergeSimilarCFUsTest < matlab.unittest.TestCase
    %MERGESIMILARCFUSTEST Tests conservative post-processing CFU merges.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            rootFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(rootFolder, 'src'), IncludingSubfolders=true));
        end
    end

    methods (Test)
        function testOverlappingSimilarNonSiblingsMerge(testCase)
            [regions, lists, parents, memberships, curves] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 20]);

            [regions, lists, parents, memberships, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyTrue(didMerge);
            testCase.verifyNumElements(regions, 1);
            testCase.verifyEqual(lists, {[1 2]});
            testCase.verifyEqual(parents, 10);
            testCase.verifyEqual(memberships{1}.MergedParentIDs, [10 20]);
            testCase.verifyEqual(nnz(regions{1} > 0.1), 7);
        end

        function testSiblingBasinsNeverBuildMergeEdge(testCase)
            [regions, lists, parents, memberships, curves] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 10]);

            [regions, lists, parents, memberships, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyFalse(didMerge);
            testCase.verifyNumElements(regions, 2);
            testCase.verifyEqual(lists, {[1]; [2]});
            testCase.verifyEqual(parents, [10; 10]);
            testCase.verifyEmpty(memberships{1}.MergedParentIDs);
        end

        function testCompleteLinkagePreventsChainMerge(testCase)
            [regions, lists, parents, memberships, curves] = ...
                mergeSimilarCFUsTest.chainFixture();

            [regions, lists, parents, ~, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyTrue(didMerge);
            testCase.verifyNumElements(regions, 2);
            testCase.verifyEqual(lists, {[1 2]; 3});
            testCase.verifyEqual(parents, [1; 3]);
        end

        function testOnePixelDilationAllowsAdjacentRegionsToMerge(testCase)
            [regions, lists, parents, memberships, curves] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 20]);
            regions{2} = mergeSimilarCFUsTest.region([1 2], [3 4]);

            [regions, lists, parents, ~, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyTrue(didMerge);
            testCase.verifyNumElements(regions, 1);
            testCase.verifyEqual(lists, {[1 2]});
            testCase.verifyEqual(parents, 10);
        end

        function testPearsonCorrelationSupportsMultiPeakCurves(testCase)
            [regions, lists, parents, memberships, ~] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 20]);
            curves = [0 1.00 0.99 0 1.01 0.99 0; ...
                0 1.01 0.99 0 1.00 0.99 0];

            [regions, ~, ~, ~, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyTrue(didMerge);
            testCase.verifyNumElements(regions, 1);
        end

        function testLargePositiveAUCDifferenceRejectsMerge(testCase)
            [regions, lists, parents, memberships, ~] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 20]);
            curves = [0 1 3 1 0; 0 0.2 0.6 0.2 0];

            [regions, ~, ~, ~, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyFalse(didMerge);
            testCase.verifyNumElements(regions, 2);
        end

        function testSharedEventMasksWithMixedOrientationsMerge(testCase)
            [regions, lists, parents, memberships, curves] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 20]);
            lists = {1; 1};
            memberships{1}.SpatialPixels = {[1; 2]};
            memberships{1}.VoxelIndices = {[11; 12]};
            memberships{2}.EventID = 1;
            memberships{2}.SpatialPixels = {[2 3]};
            memberships{2}.VoxelIndices = {[12 13]};

            [~, lists, ~, memberships, didMerge] = cfu.mergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, []);

            testCase.verifyTrue(didMerge);
            testCase.verifyEqual(lists, {1});
            testCase.verifyEqual(memberships{1}.EventID, 1);
            testCase.verifyEqual(memberships{1}.SpatialPixels{1}, [1; 2; 3]);
            testCase.verifyEqual(memberships{1}.VoxelIndices{1}, [11; 12; 13]);
        end

        function testDiagnosticsCountCorrelationRejections(testCase)
            [regions, lists, parents, memberships, ~] = ...
                mergeSimilarCFUsTest.twoCFUFixture([10; 20]);
            curves = [0 1 3 1 0 0; 3 0 1 0 3 0];
            parameters = cfu.defaultCFUMergeParameters();

            [regions, ~, ~, ~, didMerge, ~, ~, diagnostics] = ...
                cfu.mergeSimilarCFUs(regions, lists, parents, memberships, curves, parameters);

            testCase.verifyFalse(didMerge);
            testCase.verifyNumElements(regions, 2);
            testCase.verifyEqual(diagnostics.SpatialCandidatePairs, 1);
            testCase.verifyEqual(diagnostics.CorrelationRejectedPairs, 1);
            testCase.verifyEqual(diagnostics.AcceptedEdges, 0);
        end
    end

    methods (Static, Access = private)
        function [regions, lists, parents, memberships, curves] = twoCFUFixture(parents)
            first = mergeSimilarCFUsTest.region([1 2], [1 2]);
            second = mergeSimilarCFUsTest.region([2 3], [2 3]);
            regions = {first; second};
            lists = {1; 2};
            memberships = {mergeSimilarCFUsTest.membership(1); ...
                mergeSimilarCFUsTest.membership(2)};
            curves = [0 1 3 1 0; 0 1 3 1 0];
        end

        function [regions, lists, parents, memberships, curves] = chainFixture()
            first = mergeSimilarCFUsTest.region([1 2], [1 2]);
            second = mergeSimilarCFUsTest.region([1 2], [2 3 4]);
            third = mergeSimilarCFUsTest.region([1 2], [4 5]);
            regions = {first; second; third};
            lists = {1; 2; 3};
            parents = [1; 2; 3];
            memberships = {mergeSimilarCFUsTest.membership(1); ...
                mergeSimilarCFUsTest.membership(2); ...
                mergeSimilarCFUsTest.membership(3)};
            curves = repmat([0 1 3 1 0], 3, 1);
        end

        function region = region(rows, columns)
            region = zeros(5, 5, 'single');
            [rowGrid, columnGrid] = ndgrid(rows, columns);
            region(sub2ind(size(region), rowGrid(:), columnGrid(:))) = 1;
        end

        function membership = membership(eventId)
            membership = struct('EventID', eventId, 'SpatialPixels', {{eventId}}, ...
                'Score', 1, 'VoxelIndices', {{eventId}});
            membership.SupportPixels = eventId;
            membership.SupportWeights = single(1);
            membership.PrimaryPixels = eventId;
            membership.SpatialSize = [5 5];
            membership.MergedFromCFUs = [];
            membership.MergedParentIDs = [];
        end
    end
end
