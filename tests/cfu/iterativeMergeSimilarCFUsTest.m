classdef iterativeMergeSimilarCFUsTest < matlab.unittest.TestCase
    %ITERATIVEMERGESIMILARCFUSTEST Tests iterative post-processing merges.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            rootFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(rootFolder, 'src'), IncludingSubfolders=true));
        end
    end

    methods (Test)
        function testMergedCurvesAreRecomputedAndRowsStayAligned(testCase)
            [regions, lists, parents, memberships, datVec] = ...
                iterativeMergeSimilarCFUsTest.twoCFUFixture();
            [curves, dffCurves] = cfu.computeCFUCurves(regions, datVec, 1, 4);
            parameters = cfu.defaultCFUMergeParameters();
            parameters.MaximumMergeRounds = 3;

            [regions, lists, parents, memberships, curves, dffCurves, ...
                didMerge, roundsCompleted, diagnostics] = cfu.iterativeMergeSimilarCFUs( ...
                regions, lists, parents, memberships, curves, dffCurves, ...
                datVec, 1, 4, parameters);

            testCase.verifyTrue(didMerge);
            testCase.verifyEqual(roundsCompleted, 2);
            testCase.verifyNumElements(regions, 1);
            testCase.verifyEqual(lists, {[1 2]});
            testCase.verifyEqual(parents, 10);
            testCase.verifyEqual(memberships{1}.MergedParentIDs, [10 20]);
            testCase.verifySize(curves, [1 8]);
            testCase.verifySize(dffCurves, [1 8]);
            testCase.verifyEqual(curves, repmat([100 101 103 101 100 101 103 101], 1, 1), ...
                AbsTol=1e-10);
            testCase.verifyNumElements(diagnostics.Rounds, 2);
            testCase.verifyEqual(diagnostics.Total.AcceptedEdges, 1);
        end
    end

    methods (Static, Access = private)
        function [regions, lists, parents, memberships, datVec] = twoCFUFixture()
            first = iterativeMergeSimilarCFUsTest.region([1 2], [1 2]);
            second = iterativeMergeSimilarCFUsTest.region([2 3], [2 3]);
            regions = {first; second};
            lists = {1; 2};
            parents = [10; 20];
            memberships = {iterativeMergeSimilarCFUsTest.membership(1); ...
                iterativeMergeSimilarCFUsTest.membership(2)};
            datVec = repmat([100 101 103 101 100 101 103 101], 25, 1);
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
