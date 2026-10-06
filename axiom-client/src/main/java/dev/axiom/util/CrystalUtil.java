package dev.axiom.util;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import java.util.ArrayList;
import java.util.List;
public class CrystalUtil {
    private static final MinecraftClient mc = MinecraftClient.getInstance();
    public static float calculateDamage(Vec3d explosionPos, PlayerEntity target) {
        if (mc.world == null) return 0f;
        double distance = explosionPos.distanceTo(target.getPos());
        double power = 6.0;
        if (distance > power) return 0f;
        double exposure = target.getWorld().getExposure(explosionPos, target.getBoundingBox());
        double impact = (1.0 - (distance / power)) * exposure;
        float damage = (float) ((impact * impact + impact) / 2.0 * 7.0 * (power * 2.0) + 1.0);
        return damage * getDifficultyMultiplier();
    }
    public static float getDifficultyMultiplier() {
        if (mc.world == null) return 1f;
        return switch (mc.world.getDifficulty()) {
            case EASY -> 0.5f; case HARD -> 1.5f; default -> 1.0f;
        };
    }
    public static float calculateSelfDamage(Vec3d crystalPos) {
        if (mc.player == null) return 999f;
        return calculateDamage(crystalPos, mc.player);
    }
    public static List<BlockPos> getPlacementPositions(PlayerEntity target, double reach) {
        List<BlockPos> valid = new ArrayList<>();
        if (mc.world == null || mc.player == null) return valid;
        BlockPos targetPos = target.getBlockPos();
        for (int x = -2; x <= 2; x++) for (int z = -2; z <= 2; z++) for (int y = -1; y <= 2; y++) {
            BlockPos pos = targetPos.add(x, y, z);
            if (!isValidPlacement(pos)) continue;
            Vec3d center = new Vec3d(pos.getX()+0.5, pos.getY()+1.0, pos.getZ()+0.5);
            if (mc.player.getPos().distanceTo(center) > reach) continue;
            valid.add(pos);
        }
        return valid;
    }
    public static boolean isValidPlacement(BlockPos pos) {
        if (mc.world == null) return false;
        var state = mc.world.getBlockState(pos);
        if (!state.isOf(net.minecraft.block.Blocks.OBSIDIAN) && !state.isOf(net.minecraft.block.Blocks.BEDROCK)) return false;
        if (!mc.world.getBlockState(pos.up()).isAir() || !mc.world.getBlockState(pos.up(2)).isAir()) return false;
        return mc.world.getOtherEntities(null, new Box(pos.up())).isEmpty();
    }
    public static BlockPos getBestPlacement(PlayerEntity target, double reach, float maxSelf) {
        BlockPos best = null; float bestDmg = 0f;
        for (BlockPos pos : getPlacementPositions(target, reach)) {
            Vec3d cp = new Vec3d(pos.getX()+0.5, pos.getY()+1.0, pos.getZ()+0.5);
            if (calculateSelfDamage(cp) > maxSelf) continue;
            float dmg = calculateDamage(cp, target);
            if (dmg > bestDmg) { bestDmg = dmg; best = pos; }
        }
        return best;
    }
}
