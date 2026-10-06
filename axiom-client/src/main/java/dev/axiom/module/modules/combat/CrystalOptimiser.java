package dev.axiom.module.modules.combat;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventTick;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import dev.axiom.util.CrystalUtil;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.Vec3d;
public class CrystalOptimiser extends Module {
    public final NumberSetting lookahead   = register(new NumberSetting("Lookahead Ticks",3,1,10));
    public final NumberSetting maxSelf     = register(new NumberSetting("Max Self Dmg",   8,1,36));
    public final BooleanSetting preCompute = register(new BooleanSetting("Pre-Compute",   true));
    public static volatile EndCrystalEntity bestBreakTarget = null;
    public static volatile Vec3d            bestPlaceVec    = null;
    public CrystalOptimiser() { super("CrystalOptimiser","Pre-compute best crystal placements",Category.COMBAT,-1); }
    @Subscribe public void onTick(EventTick event) {
        if (event.stage!=EventTick.Stage.PRE||!preCompute.getValue()||mc.world==null||mc.player==null) return;
        PlayerEntity target=getNearestPlayer(); if(target==null){bestBreakTarget=null;bestPlaceVec=null;return;}
        Vec3d proj=target.getPos().add(target.getVelocity().multiply(lookahead.getValue()));
        EndCrystalEntity bestCrystal=null; float bestDmg=0f;
        for (var entity:mc.world.getEntities()) {
            if(!(entity instanceof EndCrystalEntity crystal))continue;
            float dmg=CrystalUtil.calculateDamage(crystal.getPos(),target);
            float self=CrystalUtil.calculateSelfDamage(crystal.getPos());
            if(self>maxSelf.getValue())continue;
            if(dmg>bestDmg){bestDmg=dmg;bestCrystal=crystal;}
        }
        bestBreakTarget=bestCrystal;
        var bestPos=CrystalUtil.getBestPlacement(target,5.0,maxSelf.getValue().floatValue());
        bestPlaceVec=bestPos!=null?new Vec3d(bestPos.getX()+0.5,bestPos.getY()+1.0,bestPos.getZ()+0.5):null;
    }
    private PlayerEntity getNearestPlayer(){
        if(mc.world==null||mc.player==null)return null;
        PlayerEntity n=null;double nd=Double.MAX_VALUE;
        for(PlayerEntity p:mc.world.getPlayers()){if(p==mc.player)continue;double d=mc.player.distanceTo(p);if(d<nd){nd=d;n=p;}}
        return n;
    }
}
