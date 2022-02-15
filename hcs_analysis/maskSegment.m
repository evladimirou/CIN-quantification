function [imgf,ul,br]=maskSegment(imgf, bb, convexHull)

[sx,sy,sz]=size(imgf);

br = min(floor(bb(1:3)+bb(4:6)), [sx sy sz]);
ul = max(floor(bb(1:3)), [1 1 1]);

if ~isempty(convexHull)
    % Compute Delaunay triangulation from convex hull and mask all pixels outside convex hull.
    ch = convexHull;
    dt = delaunayTriangulation(ch(:,1), ch(:,2), ch(:,3));
    [qpx, qpy, qpz] = meshgrid(ul(1):br(1), ul(2):br(2), ul(3):br(3)); % Query points.
    id = pointLocation(dt, qpx(:), qpy(:), qpz(:));
end
   
imgf = imgf(ul(2):br(2), ul(1):br(1), ul(3):br(3));

if ~isempty(convexHull)
    % Mask out
    imgf(isnan(id)) = 0;
end
