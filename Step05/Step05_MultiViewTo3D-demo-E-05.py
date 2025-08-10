"""
MultiView -> Voxel Carving -> Poisson -> Denoise -> Taubin Smoothing -> Multi-view Vertex Coloring
Save result -> multiview_poisson_colored.ply
"""

import numpy as np
from PIL import Image
import open3d as o3d
import math
import time
import sys

# ---------- user parameters (tune for speed/quality) ----------
images = [
    ("./input/360_view_001_000deg_from_000deg.png", 0.0),
    ("./input/360_view_002_045deg_from_060deg.png", 45.0),
    ("./input/360_view_003_090deg_from_090deg.png", 90.0),
    ("./input/360_view_004_135deg_from_090deg.png", 135.0),
    ("./input/360_view_005_180deg_from_180deg.png", 180.0),
    ("./input/360_view_006_225deg_from_240deg.png", 225.0),
    ("./input/360_view_007_270deg_from_270deg.png", 270.0),
    ("./input/360_view_008_315deg_from_000deg.png", 315.0),
]

N = 160                 # voxel grid resolution (increase -> better detail, slower, more memory)
MASK_DIFF_THRESH = 30.0 # mask threshold for bg subtraction
POISSON_DEPTH = 9       # poisson reconstruction depth (6-10 typical)
DENSITY_QUANTILE = 0.02 # remove vertices with density < quantile
SMOOTH_ITERS = 10       # Taubin smoothing iterations
VIS_EPS_FACTOR = 1.5    # visibility z tolerance factor (multiplied by voxel size)
# -------------------------------------------------------------

def load_images_and_masks(images):
    imgs = []
    masks = []
    for path, ang in images:
        im = Image.open(path).convert("RGB")
        im_np = np.array(im)
        h, w = im_np.shape[:2]
        bg = im_np[0, 0].astype(np.float32)
        diff = np.linalg.norm(im_np.astype(np.float32) - bg[None, None, :], axis=2)
        mask = diff > MASK_DIFF_THRESH
        imgs.append((im_np, w, h, path))
        masks.append(mask)
    return imgs, masks

def voxel_carving(imgs, masks, images, N):
    xs = np.linspace(-1, 1, N)
    ys = np.linspace(-1, 1, N)
    zs = np.linspace(-1, 1, N)
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing='ij')
    volume = np.ones((N, N, N), dtype=bool)

    total_views = len(images)
    for idx, ((img_np, w, h, path), mask, (pth, angle_deg)) in enumerate(zip(imgs, masks, images)):
        theta = math.radians(angle_deg)
        cos_t = math.cos(theta); sin_t = math.sin(theta)
        Xr = cos_t * X + sin_t * Z
        Zr = -sin_t * X + cos_t * Z
        Yr = Y

        u = ((Xr + 1.0) / 2.0 * (w - 1)).astype(int)
        v = ((-Yr + 1.0) / 2.0 * (h - 1)).astype(int)

        valid = (u >= 0) & (u < w) & (v >= 0) & (v < h)
        keep = np.zeros_like(volume, dtype=bool)
        valid_idx = np.where(valid)
        if valid_idx[0].size > 0:
            ui = u[valid_idx]; vi = v[valid_idx]
            mask_vals = mask[vi, ui]
            keep[valid_idx] = mask_vals
        volume &= keep
        print(f"[Carving] view {idx+1}/{total_views} angle={angle_deg}°, remaining voxels = {np.count_nonzero(volume)}")
    return volume

def voxels_to_pcd(volume):
    idx = np.argwhere(volume)
    if idx.shape[0] == 0:
        raise RuntimeError("No voxels remain after carving. Check masks or reduce carving aggressiveness.")
    Nloc = volume.shape[0]
    pts = idx.astype(np.float32) / Nloc * 2.0 - 1.0
    return pts

def build_depth_maps_from_voxels(volume, imgs_masks_images):
    imgs, masks, images = imgs_masks_images
    Nloc = volume.shape[0]
    pts_idx = np.argwhere(volume)
    pts_world = pts_idx.astype(np.float32) / Nloc * 2.0 - 1.0

    depth_maps = []
    for (img_np, w, h, _), mask, (pth, angle_deg) in zip(imgs, masks, images):
        depth_map = np.full((h, w), np.inf, dtype=np.float32)
        theta = math.radians(angle_deg)
        cos_t = math.cos(theta); sin_t = math.sin(theta)

        Xw = pts_world[:,0]; Yw = pts_world[:,1]; Zw = pts_world[:,2]
        Xr = cos_t * Xw + sin_t * Zw
        Zr = -sin_t * Xw + cos_t * Zw
        Yr = Yw

        u = np.floor((Xr + 1.0) / 2.0 * (w - 1)).astype(int)
        v = np.floor((-Yr + 1.0) / 2.0 * (h - 1)).astype(int)
        valid = (u >= 0) & (u < w) & (v >= 0) & (v < h)

        for ui, vi, zr in zip(u[valid], v[valid], Zr[valid]):
            if zr < depth_map[vi, ui]:
                depth_map[vi, ui] = zr
        depth_maps.append(depth_map)
    return depth_maps

def color_mesh_vertices(mesh, imgs_masks_images, depth_maps, voxel_size):
    verts = np.asarray(mesh.vertices)
    normals = np.asarray(mesh.vertex_normals)
    vcolors = np.zeros_like(verts, dtype=np.float32)

    imgs, masks, images = imgs_masks_images
    VIS_EPS = voxel_size * VIS_EPS_FACTOR

    for vi, (v, n) in enumerate(zip(verts, normals)):
        # NaN 버텍스 필터링
        if not np.isfinite(v).all() or not np.isfinite(n).all():
            vcolors[vi] = np.array([0.5, 0.5, 0.5], dtype=np.float32)
            continue

        color_acc = np.zeros(3, dtype=np.float32)
        weight_acc = 0.0
        for i, ((img_np, w, h, _), mask, (pth, angle_deg)) in enumerate(zip(imgs, masks, images)):
            theta = math.radians(angle_deg)
            cos_t = math.cos(theta); sin_t = math.sin(theta)
            Xr = cos_t * v[0] + sin_t * v[2]
            Zr = -sin_t * v[0] + cos_t * v[2]
            Yr = v[1]

            u_f = (Xr + 1.0) / 2.0 * (w - 1)
            v_f = (-Yr + 1.0) / 2.0 * (h - 1)

            # NaN 좌표 필터링
            if not np.isfinite(u_f) or not np.isfinite(v_f):
                continue

            u = int(round(u_f))
            vv = int(round(v_f))
            if not (0 <= u < w and 0 <= vv < h):
                continue
            if not mask[vv, u]:
                continue

            depth_map = depth_maps[i]
            depth_at_pixel = depth_map[vv, u]
            if not np.isfinite(depth_at_pixel):
                continue
            if abs(Zr - depth_at_pixel) > VIS_EPS:
                continue

            view_dir = np.array([math.sin(theta), 0.0, math.cos(theta)], dtype=np.float32)
            facing = np.dot(n, view_dir)
            if facing <= 0.0:
                continue

            col = img_np[vv, u].astype(np.float32) / 255.0
            weight = max(1e-6, facing)
            color_acc += col * weight
            weight_acc += weight

        if weight_acc > 0.0:
            vcolors[vi] = color_acc / weight_acc
        else:
            vcolors[vi] = np.array([0.8, 0.8, 0.8], dtype=np.float32)

        if (vi % 5000) == 0:
            print(f"[Color] vertex {vi}/{len(verts)}")

    mesh.vertex_colors = o3d.utility.Vector3dVector(vcolors)
    return mesh

def main():
    t0 = time.time()
    print("Loading images and estimating masks...")
    imgs, masks = load_images_and_masks(images)
    imgs_masks_images = (imgs, masks, images)

    print("Running voxel carving...")
    volume = voxel_carving(imgs, masks, images, N)
    rem = np.count_nonzero(volume)
    print(f"Carving finished. remaining voxels: {rem}")
    if rem == 0:
        print("No voxels remain. Aborting.")
        return

    print("Converting voxels to point cloud...")
    pts = voxels_to_pcd(volume)
    pcd = o3d.geometry.PointCloud(o3d.utility.Vector3dVector(pts))
    print("Estimating normals on point cloud...")
    pcd.estimate_normals(search_param=o3d.geometry.KDTreeSearchParamHybrid(radius=0.05, max_nn=30))
    pcd.normalize_normals()

    mesh = None
    try:
        print("Poisson reconstruction (this may take a while)...")
        mesh, densities = o3d.geometry.TriangleMesh.create_from_point_cloud_poisson(pcd, depth=POISSON_DEPTH)
        densities = np.asarray(densities)
        print("Poisson done. vertices:", np.asarray(mesh.vertices).shape[0])

        # remove low-density vertices (noise)
        thr = np.quantile(densities, DENSITY_QUANTILE)
        print(f"Density threshold at quantile {DENSITY_QUANTILE}: {thr:.6f}")
        remove_mask = densities < thr
        print(f"Removing {np.count_nonzero(remove_mask)} low-density vertices...")
        mesh.remove_vertices_by_mask(remove_mask)

    except Exception as e:
        print("Poisson failed:", e)
        print("Falling back to Ball Pivoting")
        radii = o3d.utility.DoubleVector([0.02, 0.04, 0.08])
        mesh = o3d.geometry.TriangleMesh.create_from_point_cloud_ball_pivoting(pcd, radii)

    # cleanup and smoothing
    print("Cleaning mesh (degenerate/duplicate/non-manifold)...")
    mesh.remove_degenerate_triangles()
    mesh.remove_duplicated_triangles()
    mesh.remove_duplicated_vertices()
    mesh.remove_non_manifold_edges()

    print(f"Applying Taubin smoothing ({SMOOTH_ITERS} iterations)...")
    mesh = mesh.filter_smooth_taubin(number_of_iterations=SMOOTH_ITERS)
    mesh.compute_vertex_normals()

    # build depth maps from final voxel set for visibility checks
    print("Building depth maps from voxels for visibility tests...")
    depth_maps = build_depth_maps_from_voxels(volume, imgs_masks_images)

    print("Applying multi-view vertex coloring...")
    voxel_size = 2.0 / N
    mesh = color_mesh_vertices(mesh, imgs_masks_images, depth_maps, voxel_size)

    outname = "multiview_poisson_colored.ply"
    print(f"Saving mesh to {outname} ...")
    o3d.io.write_triangle_mesh(outname, mesh, write_ascii=False)
    print("Done. Visualizing result...")
    o3d.visualization.draw_geometries([mesh], mesh_show_back_face=True)

    print("Total time: %.1f sec" % (time.time() - t0))

if __name__ == "__main__":
    main()
