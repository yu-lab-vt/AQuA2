classdef membershipTimeWindowsTest < matlab.unittest.TestCase
    %MEMBERSHIPTIMEWINDOWSTEST Tests multi-label CFU curve time windows.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            rootFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(rootFolder, 'src'), IncludingSubfolders=true));
        end
    end

    methods (Test)
        function testSharedEventMarksEveryAssignedCFUAsOwn(testCase)
            [memberships, regions, sz] = membershipTimeWindowsTest.sharedEventFixture();

            [ownWindows, nonWindows, overlaps] = cfu.membershipTimeWindows( ...
                memberships, regions, sz);

            testCase.verifyEqual(ownWindows, logical([1 0 1 0; 1 1 1 0]));
            testCase.verifyEqual(nonWindows, logical([0 1 0 0; 0 0 0 0]));
            testCase.verifyEqual(overlaps, {[2]; [1]});
        end
    end

    methods (Static, Access = private)
        function [memberships, regions, sz] = sharedEventFixture()
            sz = [5 5 1 4];
            nSpatialPixels = prod(sz(1:3));
            sharedVoxels = [1; 1 + 2 * nSpatialPixels];
            foreignVoxels = 1 + nSpatialPixels;
            first = struct('EventID', 1, 'SpatialPixels', {{1}}, ...
                'Score', 1, 'VoxelIndices', {{sharedVoxels}});
            second = struct('EventID', [1 2], 'SpatialPixels', {{1, 1}}, ...
                'Score', [1 1], 'VoxelIndices', {{sharedVoxels, foreignVoxels}});
            memberships = {first; second};
            region = zeros(sz(1:3), 'single');
            region(1) = 1;
            regions = {region; region};
        end
    end
end
