package dev.axiom.util;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
public class RotationUtil {
    private static final MinecraftClient mc = MinecraftClient.getInstance();
    public static float[] getRotationsToVec(Vec3d target) {
        if (mc.player == null) return new float[]{0, 0};
        Vec3d eyes = mc.player.getEyePos();
        double dx = target.x-eyes.x, dy = target.y-eyes.y, dz = target.z-eyes.z;
        double dist = Math.sqrt(dx*dx+dz*dz);
        float yaw = (float) Math.toDegrees(Math.atan2(dz, dx)) - 90f;
        float pitch = (float) -Math.toDegrees(Math.atan2(dy, dist));
        return new float[]{yaw, MathHelper.clamp(pitch, -90f, 90f)};
    }
    public static float[] smoothRotation(float cy, float cp, float ty, float tp, float speed) {
        float yawDiff = MathHelper.wrapDegrees(ty - cy);
        float pitchDiff = tp - cp;
        return new float[]{cy + MathHelper.clamp(yawDiff,-speed,speed),
                           MathHelper.clamp(cp + MathHelper.clamp(pitchDiff,-speed,speed),-90f,90f)};
    }
}
