package dev.axiom.module.modules.combat;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventTick;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import dev.axiom.util.*;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.*;
public class AutoCrystal extends Module {
    public final NumberSetting placeRange = register(new NumberSetting("Place Range", 4.5, 1, 6));
    public final NumberSetting breakRange = register(new NumberSetting("Break Range", 4.5, 1, 6));
    public final NumberSetting minDamage  = register(new NumberSetting("Min Damage",  6.0, 1, 36));
    public final NumberSetting maxSelf    = register(new NumberSetting("Max Self Dmg",8.0, 1, 36));
    public final NumberSetting placeDelay = register(new NumberSetting("Place Delay", 1,   0, 10));
    public final NumberSetting breakDelay = register(new NumberSetting("Break Delay", 0,   0, 10));
    public final BooleanSetting antiSuicide = register(new BooleanSetting("Anti Suicide", true));
    public final BooleanSetting autoSwitch  = register(new BooleanSetting("Auto Switch",  true));
    public final ModeSetting rotationMode   = register(new ModeSetting("Rotations","Silent","Silent","None"));
    private int placeTimer = 0, breakTimer = 0;
    public AutoCrystal() { super("AutoCrystal","Auto place and explode end crystals",Category.COMBAT,-1); }
    @Subscribe public void onTick(EventTick event) {
        if (event.stage != EventTick.Stage.PRE || mc.player == null || mc.world == null) return;
        PlayerEntity target = getNearestPlayer();
        if (target == null) return;
        if (breakTimer <= 0) {
            for (var entity : mc.world.getEntities()) {
                if (!(entity instanceof EndCrystalEntity crystal)) continue;
                if (mc.player.getPos().distanceTo(crystal.getPos()) > breakRange.getValue()) continue;
                float dmg = CrystalUtil.calculateDamage(crystal.getPos(), target);
                if (dmg < minDamage.getValue()) continue;
                if (antiSuicide.getValue() && mc.player.getHealth() - CrystalUtil.calculateSelfDamage(crystal.getPos()) <= 0.5f) continue;
                attackCrystal(crystal); breakTimer = breakDelay.getValue().intValue(); break;
            }
        } else breakTimer--;
        if (placeTimer <= 0) {
            BlockPos best = CrystalUtil.getBestPlacement(target, placeRange.getValue(), maxSelf.getValue().floatValue());
            if (best != null) {
                float dmg = CrystalUtil.calculateDamage(new Vec3d(best.getX()+0.5,best.getY()+1.0,best.getZ()+0.5), target);
                if (dmg >= minDamage.getValue()) { placeCrystal(best); placeTimer = placeDelay.getValue().intValue(); }
            }
        } else placeTimer--;
    }
    private void placeCrystal(BlockPos pos) {
        if (autoSwitch.getValue()) { int slot = InventoryUtil.findCrystal(); if (slot==-1) return; InventoryUtil.switchTo(slot); }
        Vec3d hitVec = new Vec3d(pos.getX()+0.5, pos.getY()+1.0, pos.getZ()+0.5);
        if (rotationMode.getValue().equals("Silent")) { float[] r = RotationUtil.getRotationsToVec(hitVec); mc.player.setYaw(r[0]); mc.player.setPitch(r[1]); }
        mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND, new BlockHitResult(hitVec, Direction.UP, pos, false));
        mc.player.swingHand(Hand.MAIN_HAND);
    }
    private void attackCrystal(EndCrystalEntity crystal) {
        if (rotationMode.getValue().equals("Silent")) { float[] r = RotationUtil.getRotationsToVec(crystal.getPos()); mc.player.setYaw(r[0]); mc.player.setPitch(r[1]); }
        mc.interactionManager.attackEntity(mc.player, crystal);
        mc.player.swingHand(Hand.MAIN_HAND);
    }
    private PlayerEntity getNearestPlayer() {
        if (mc.world==null||mc.player==null) return null;
        PlayerEntity n=null; double nd=Double.MAX_VALUE;
        for (PlayerEntity p : mc.world.getPlayers()) { if (p==mc.player) continue; double d=mc.player.distanceTo(p); if (d<nd){nd=d;n=p;} }
        return n;
    }
}
