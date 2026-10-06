package dev.axiom.mixin;
import dev.axiom.AxiomClient;
import dev.axiom.event.events.EventRender3D;
import dev.axiom.module.modules.visual.Cosmetics;
import net.minecraft.client.render.GameRenderer;
import net.minecraft.client.util.math.MatrixStack;
import org.joml.Matrix4f;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.*;
import org.spongepowered.asm.mixin.injection.callback.*;
@Mixin(GameRenderer.class)
public class MixinGameRenderer {
    @Inject(method="renderWorld",at=@At("HEAD"))
    private void onRenderWorld(float tickDelta,long limitTime,MatrixStack matrices,CallbackInfo ci){
        AxiomClient.EVENT_BUS.post(new EventRender3D(matrices,tickDelta));
    }
    @Inject(method="getBasicProjectionMatrix",at=@At("RETURN"),cancellable=true)
    private void onProjectionMatrix(double fov,CallbackInfoReturnable<Matrix4f> cir){
        Cosmetics cos=AxiomClient.MODULE_MANAGER.get(Cosmetics.class);
        if(cos==null||!cos.isEnabled()) return;
        float aspect=cos.getAspectOverride(); if(aspect<0) return;
        cir.setReturnValue(new Matrix4f().perspective((float)Math.toRadians(fov),aspect,0.05f,65536f));
    }
}
