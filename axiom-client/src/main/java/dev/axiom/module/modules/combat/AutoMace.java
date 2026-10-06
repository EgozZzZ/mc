package dev.axiom.module.modules.combat;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventTick;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import dev.axiom.util.InventoryUtil;
import net.minecraft.entity.player.PlayerEntity;
public class AutoMace extends Module {
    public final NumberSetting range       = register(new NumberSetting("Range",        4.5,1,6));
    public final NumberSetting minFallDist = register(new NumberSetting("Min Fall Dist",3.0,1,20));
    public final BooleanSetting autoSwitch = register(new BooleanSetting("Auto Switch", true));
    public final BooleanSetting requireCrit= register(new BooleanSetting("Require Crit",true));
    private boolean pouncing=false; private double pounceStartY=0;
    public AutoMace() { super("AutoMace","Attack with Mace fall damage",Category.COMBAT,-1); }
    @Override protected void onEnable() { pouncing=false; }
    @Subscribe public void onTick(EventTick event) {
        if (event.stage!=EventTick.Stage.PRE||mc.player==null||mc.world==null) return;
        PlayerEntity target=getNearestPlayer(); if(target==null) return;
        if (mc.player.distanceTo(target)>range.getValue()){pouncing=false;return;}
        boolean falling=mc.player.getVelocity().y<-0.1;
        double fallDist=pouncing?(pounceStartY-mc.player.getY()):mc.player.fallDistance;
        if (!pouncing&&mc.player.isOnGround()){mc.player.jump();pounceStartY=mc.player.getY();pouncing=true;}
        if (pouncing&&falling&&fallDist>=minFallDist.getValue()) {
            if (requireCrit.getValue()&&!isCritical()){return;}
            if (autoSwitch.getValue()){int slot=InventoryUtil.findMace();if(slot==-1){pouncing=false;return;}InventoryUtil.switchTo(slot);}
            mc.interactionManager.attackEntity(mc.player,target);
            mc.player.swingHand(net.minecraft.util.Hand.MAIN_HAND);
            pouncing=false;
        }
    }
    private boolean isCritical(){return mc.player!=null&&mc.player.getVelocity().y<0&&!mc.player.isOnGround()&&!mc.player.isInFluid()&&!mc.player.hasStatusEffect(net.minecraft.entity.effect.StatusEffects.BLINDNESS);}
    private PlayerEntity getNearestPlayer(){
        if(mc.world==null||mc.player==null)return null;
        PlayerEntity n=null;double nd=Double.MAX_VALUE;
        for(PlayerEntity p:mc.world.getPlayers()){if(p==mc.player)continue;double d=mc.player.distanceTo(p);if(d<nd){nd=d;n=p;}}
        return n;
    }
}
