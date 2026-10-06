package dev.axiom.mixin;
import dev.axiom.AxiomClient;
import dev.axiom.event.events.EventTick;
import net.minecraft.client.MinecraftClient;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.*;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
@Mixin(MinecraftClient.class)
public class MixinMinecraftClient {
    @Inject(method="tick",at=@At("HEAD"))
    private void onTickPre(CallbackInfo ci){ AxiomClient.EVENT_BUS.post(new EventTick(EventTick.Stage.PRE)); }
    @Inject(method="tick",at=@At("TAIL"))
    private void onTickPost(CallbackInfo ci){ AxiomClient.EVENT_BUS.post(new EventTick(EventTick.Stage.POST)); }
}
