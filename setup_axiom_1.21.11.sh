#!/bin/bash
# Axiom Client — full project setup script
# Run: bash setup_axiom.sh
# Then: cd axiom-client && ./gradlew build

set -e
ROOT="axiom-client"
SRC="$ROOT/src/main/java/dev/axiom"
RES="$ROOT/src/main/resources"
mkdir -p "$SRC/event/events" "$SRC/module/modules/combat" "$SRC/module/modules/visual"
mkdir -p "$SRC/setting" "$SRC/gui/clicks" "$SRC/mixin" "$SRC/util"
mkdir -p "$RES/assets/axiomclient/lang"
mkdir -p "$ROOT/gradle/wrapper"

# ── gradle wrapper properties ──────────────────────────────────────────────
cat > "$ROOT/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.8-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# ── settings.gradle ────────────────────────────────────────────────────────
cat > "$ROOT/settings.gradle" << 'EOF'
pluginManagement {
    repositories {
        maven { url = "https://maven.fabricmc.net/" }
        gradlePluginPortal()
    }
}
rootProject.name = "axiom-client"
EOF

# ── gradle.properties ─────────────────────────────────────────────────────
cat > "$ROOT/gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2G
minecraft_version=1.21.11
yarn_mappings=1.21.11+build.6
loader_version=0.19.5
loom_version=1.18-SNAPSHOT
fabric_api_version=0.141.6+1.21.11
mod_version=1.0.0
maven_group=dev.axiom
archives_base_name=axiom-client
EOF

# ── build.gradle ───────────────────────────────────────────────────────────
cat > "$ROOT/build.gradle" << 'EOF'
plugins {
    id 'fabric-loom' version "${project.loom_version}"
    id 'java'
}
group = project.maven_group
version = project.mod_version
archivesBaseName = project.archives_base_name
repositories { mavenCentral() }
dependencies {
    minecraft "com.mojang:minecraft:${project.minecraft_version}"
    mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"
    modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_api_version}"
}
java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}
tasks.withType(JavaCompile).configureEach { it.options.release = 21 }
EOF

# ── fabric.mod.json ────────────────────────────────────────────────────────
cat > "$RES/fabric.mod.json" << 'EOF'
{
  "schemaVersion": 1,
  "id": "axiomclient",
  "version": "${version}",
  "name": "Axiom Client",
  "description": "PvP client — AutoCrystal, AutoMace, CrystalOptimiser, Cosmetics, ClickGUI",
  "authors": ["Axiom"],
  "license": "MIT",
  "environment": "client",
  "entrypoints": { "client": ["dev.axiom.AxiomClient"] },
  "mixins": ["axiom.mixins.json"],
  "depends": {
    "fabricloader": ">=0.15.0",
    "minecraft": "~1.21.11",
    "java": ">=21",
    "fabric-api": "*"
  }
}
EOF

# ── axiom.mixins.json ──────────────────────────────────────────────────────
cat > "$RES/axiom.mixins.json" << 'EOF'
{
  "required": true,
  "minVersion": "0.8",
  "package": "dev.axiom.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins": ["MixinMinecraftClient","MixinGameRenderer"],
  "client": [],
  "injectors": { "defaultRequire": 1 }
}
EOF

# ── lang ───────────────────────────────────────────────────────────────────
cat > "$RES/assets/axiomclient/lang/en_us.json" << 'EOF'
{ "key.axiomclient.open_gui": "Open Axiom GUI" }
EOF

# ══════════════════════════════════════════════════════════════════════════════
# JAVA SOURCE FILES
# ══════════════════════════════════════════════════════════════════════════════

cat > "$SRC/AxiomClient.java" << 'EOF'
package dev.axiom;
import dev.axiom.event.EventBus;
import dev.axiom.module.ModuleManager;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
public class AxiomClient implements ClientModInitializer {
    public static final String NAME = "Axiom";
    public static final String VERSION = "1.0.0";
    public static final Logger LOGGER = LoggerFactory.getLogger(NAME);
    public static final MinecraftClient mc = MinecraftClient.getInstance();
    public static AxiomClient INSTANCE;
    public static EventBus EVENT_BUS;
    public static ModuleManager MODULE_MANAGER;
    public static KeyBinding GUI_KEY;
    @Override
    public void onInitializeClient() {
        INSTANCE = this;
        EVENT_BUS = new EventBus();
        MODULE_MANAGER = new ModuleManager();
        MODULE_MANAGER.init();
        GUI_KEY = KeyBindingHelper.registerKeyBinding(new KeyBinding(
            "key.axiomclient.open_gui", InputUtil.Type.KEYSYM,
            GLFW.GLFW_KEY_RIGHT_SHIFT, "Axiom Client"
        ));
        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (GUI_KEY.wasPressed()) {
                if (client.currentScreen == null)
                    client.setScreen(new dev.axiom.gui.clicks.AxiomGUIScreen());
            }
        });
        LOGGER.info("[Axiom] {} modules loaded.", MODULE_MANAGER.getModules().size());
    }
}
EOF

cat > "$SRC/event/EventBus.java" << 'EOF'
package dev.axiom.event;
import java.lang.reflect.Method;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
public class EventBus {
    private final Map<Class<?>, List<ListenerMethod>> listeners = new ConcurrentHashMap<>();
    public void subscribe(Object object) {
        for (Method method : object.getClass().getDeclaredMethods()) {
            if (method.isAnnotationPresent(Subscribe.class) && method.getParameterCount() == 1) {
                Class<?> eventType = method.getParameterTypes()[0];
                listeners.computeIfAbsent(eventType, k -> new ArrayList<>())
                         .add(new ListenerMethod(object, method));
            }
        }
    }
    public void unsubscribe(Object object) {
        listeners.values().forEach(list -> list.removeIf(lm -> lm.instance == object));
    }
    public void post(Object event) {
        List<ListenerMethod> list = listeners.get(event.getClass());
        if (list == null) return;
        for (ListenerMethod lm : list) {
            try { lm.method.invoke(lm.instance, event); }
            catch (Exception e) { dev.axiom.AxiomClient.LOGGER.error("EventBus error", e); }
        }
    }
    private record ListenerMethod(Object instance, Method method) {}
}
EOF

cat > "$SRC/event/Subscribe.java" << 'EOF'
package dev.axiom.event;
import java.lang.annotation.*;
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Subscribe {}
EOF

cat > "$SRC/event/events/EventTick.java" << 'EOF'
package dev.axiom.event.events;
public class EventTick {
    public enum Stage { PRE, POST }
    public final Stage stage;
    public EventTick(Stage stage) { this.stage = stage; }
}
EOF

cat > "$SRC/event/events/EventMotion.java" << 'EOF'
package dev.axiom.event.events;
public class EventMotion {
    public float yaw, pitch;
    public boolean cancelled;
    public EventMotion(float yaw, float pitch) { this.yaw = yaw; this.pitch = pitch; }
}
EOF

cat > "$SRC/event/events/EventRender3D.java" << 'EOF'
package dev.axiom.event.events;
import net.minecraft.client.util.math.MatrixStack;
public class EventRender3D {
    public final MatrixStack matrices;
    public final float tickDelta;
    public EventRender3D(MatrixStack matrices, float tickDelta) {
        this.matrices = matrices; this.tickDelta = tickDelta;
    }
}
EOF

cat > "$SRC/module/Category.java" << 'EOF'
package dev.axiom.module;
public enum Category { COMBAT, VISUAL, MOVEMENT, WORLD, PLAYER, MISC }
EOF

cat > "$SRC/module/Module.java" << 'EOF'
package dev.axiom.module;
import dev.axiom.AxiomClient;
import dev.axiom.setting.Setting;
import net.minecraft.client.MinecraftClient;
import java.util.ArrayList;
import java.util.List;
public abstract class Module {
    protected static final MinecraftClient mc = MinecraftClient.getInstance();
    public final String name, description;
    public final Category category;
    public int keybind;
    private boolean enabled;
    protected final List<Setting<?>> settings = new ArrayList<>();
    public Module(String name, String description, Category category, int keybind) {
        this.name = name; this.description = description;
        this.category = category; this.keybind = keybind;
    }
    public void toggle() { setEnabled(!enabled); }
    public void setEnabled(boolean state) {
        this.enabled = state;
        if (state) { AxiomClient.EVENT_BUS.subscribe(this); onEnable(); }
        else { AxiomClient.EVENT_BUS.unsubscribe(this); onDisable(); }
    }
    public boolean isEnabled() { return enabled; }
    protected void onEnable() {}
    protected void onDisable() {}
    protected <T extends Setting<?>> T register(T s) { settings.add(s); return s; }
    public List<Setting<?>> getSettings() { return settings; }
}
EOF

cat > "$SRC/module/ModuleManager.java" << 'EOF'
package dev.axiom.module;
import dev.axiom.module.modules.combat.*;
import dev.axiom.module.modules.visual.*;
import java.util.ArrayList;
import java.util.List;
public class ModuleManager {
    private final List<Module> modules = new ArrayList<>();
    public void init() {
        register(new AutoCrystal());
        register(new AutoMace());
        register(new CrystalOptimiser());
        register(new ESP());
        register(new HUD());
        register(new ClickGUI());
        register(new Cosmetics());
    }
    private void register(Module m) { modules.add(m); }
    public List<Module> getModules() { return modules; }
    public <T extends Module> T get(Class<T> clazz) {
        return modules.stream().filter(m -> m.getClass() == clazz)
                .map(clazz::cast).findFirst().orElse(null);
    }
    public Module getByName(String name) {
        return modules.stream().filter(m -> m.name.equalsIgnoreCase(name))
                .findFirst().orElse(null);
    }
}
EOF

cat > "$SRC/setting/Setting.java" << 'EOF'
package dev.axiom.setting;
public abstract class Setting<T> {
    public final String name;
    protected T value;
    public Setting(String name, T defaultValue) { this.name = name; this.value = defaultValue; }
    public T getValue() { return value; }
    public void setValue(T value) { this.value = value; }
}
EOF

cat > "$SRC/setting/BooleanSetting.java" << 'EOF'
package dev.axiom.setting;
public class BooleanSetting extends Setting<Boolean> {
    public BooleanSetting(String name, boolean defaultValue) { super(name, defaultValue); }
    public void toggle() { value = !value; }
}
EOF

cat > "$SRC/setting/NumberSetting.java" << 'EOF'
package dev.axiom.setting;
public class NumberSetting extends Setting<Double> {
    public final double min, max;
    public NumberSetting(String name, double defaultValue, double min, double max) {
        super(name, defaultValue); this.min = min; this.max = max;
    }
    @Override public void setValue(Double value) {
        this.value = Math.max(min, Math.min(max, value));
    }
}
EOF

cat > "$SRC/setting/ModeSetting.java" << 'EOF'
package dev.axiom.setting;
import java.util.List;
public class ModeSetting extends Setting<String> {
    public final List<String> modes;
    public ModeSetting(String name, String defaultMode, String... modes) {
        super(name, defaultMode); this.modes = List.of(modes);
    }
    public void cycle() {
        int idx = modes.indexOf(value);
        value = modes.get((idx + 1) % modes.size());
    }
}
EOF

cat > "$SRC/util/CrystalUtil.java" << 'EOF'
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
EOF

cat > "$SRC/util/RotationUtil.java" << 'EOF'
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
EOF

cat > "$SRC/util/InventoryUtil.java" << 'EOF'
package dev.axiom.util;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Item;
import net.minecraft.item.Items;
public class InventoryUtil {
    private static final MinecraftClient mc = MinecraftClient.getInstance();
    public static int findItem(Item item) {
        if (mc.player == null) return -1;
        for (int i = 0; i < 9; i++)
            if (mc.player.getInventory().getStack(i).isOf(item)) return i;
        return -1;
    }
    public static int findCrystal() { return findItem(Items.END_CRYSTAL); }
    public static int findMace()    { return findItem(Items.MACE); }
    public static int findTotem()   { return findItem(Items.TOTEM_OF_UNDYING); }
    public static void switchTo(int slot) {
        if (mc.player == null || slot < 0 || slot > 8) return;
        mc.player.getInventory().selectedSlot = slot;
    }
}
EOF

cat > "$SRC/util/RenderUtil.java" << 'EOF'
package dev.axiom.util;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.*;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.entity.LivingEntity;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import org.joml.Matrix4f;
public class RenderUtil {
    private static final MinecraftClient mc = MinecraftClient.getInstance();
    public static void drawBox(MatrixStack matrices, Box box, int fillColor, int outlineColor) {
        Vec3d cam = mc.gameRenderer.getCamera().getPos();
        matrices.push();
        matrices.translate(-cam.x, -cam.y, -cam.z);
        Tessellator tess = Tessellator.getInstance();
        BufferBuilder buf = tess.begin(VertexFormat.DrawMode.QUADS, VertexFormats.POSITION_COLOR);
        Matrix4f mat = matrices.peek().getPositionMatrix();
        float r=((fillColor>>16)&0xFF)/255f, g=((fillColor>>8)&0xFF)/255f, b=(fillColor&0xFF)/255f, a=((fillColor>>24)&0xFF)/255f;
        addBox(buf, mat, box, r, g, b, a);
        tess.draw();
        matrices.pop();
    }
    private static void addBox(BufferBuilder buf, Matrix4f mat, Box b, float r, float g, float bl, float a) {
        float x0=(float)b.minX,x1=(float)b.maxX,y0=(float)b.minY,y1=(float)b.maxY,z0=(float)b.minZ,z1=(float)b.maxZ;
        buf.vertex(mat,x0,y0,z0).color(r,g,bl,a); buf.vertex(mat,x1,y0,z0).color(r,g,bl,a);
        buf.vertex(mat,x1,y0,z1).color(r,g,bl,a); buf.vertex(mat,x0,y0,z1).color(r,g,bl,a);
        buf.vertex(mat,x0,y1,z0).color(r,g,bl,a); buf.vertex(mat,x1,y1,z0).color(r,g,bl,a);
        buf.vertex(mat,x1,y1,z1).color(r,g,bl,a); buf.vertex(mat,x0,y1,z1).color(r,g,bl,a);
    }
    public static void drawTracer(MatrixStack matrices, Vec3d target, int color) {
        if (mc.player == null) return;
        Vec3d cam = mc.gameRenderer.getCamera().getPos();
        Vec3d screen = mc.player.getEyePos();
        matrices.push();
        matrices.translate(-cam.x, -cam.y, -cam.z);
        Tessellator tess = Tessellator.getInstance();
        BufferBuilder buf = tess.begin(VertexFormat.DrawMode.DEBUG_LINES, VertexFormats.POSITION_COLOR);
        Matrix4f mat = matrices.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f, g=((color>>8)&0xFF)/255f, bl=(color&0xFF)/255f;
        buf.vertex(mat,(float)screen.x,(float)screen.y,(float)screen.z).color(r,g,bl,1f);
        buf.vertex(mat,(float)target.x,(float)target.y,(float)target.z).color(r,g,bl,1f);
        tess.draw();
        matrices.pop();
    }
    public static void drawHealthBar(MatrixStack matrices, LivingEntity entity) {}
}
EOF

cat > "$SRC/module/modules/combat/AutoCrystal.java" << 'EOF'
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
EOF

cat > "$SRC/module/modules/combat/AutoMace.java" << 'EOF'
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
EOF

cat > "$SRC/module/modules/combat/CrystalOptimiser.java" << 'EOF'
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
EOF

cat > "$SRC/module/modules/visual/ESP.java" << 'EOF'
package dev.axiom.module.modules.visual;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventRender3D;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import dev.axiom.util.RenderUtil;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
public class ESP extends Module {
    public final BooleanSetting players    = register(new BooleanSetting("Players",    true));
    public final BooleanSetting crystals   = register(new BooleanSetting("Crystals",   true));
    public final BooleanSetting tracers    = register(new BooleanSetting("Tracers",    false));
    public final BooleanSetting healthBars = register(new BooleanSetting("Health Bars",true));
    public ESP() { super("ESP","Entity box and tracer ESP",Category.VISUAL,-1); }
    @Subscribe public void onRender3D(EventRender3D event) {
        if (mc.world==null||mc.player==null) return;
        for (var entity:mc.world.getEntities()) {
            if (entity==mc.player) continue;
            if (players.getValue()&&entity instanceof PlayerEntity player) {
                RenderUtil.drawBox(event.matrices,player.getBoundingBox(),0x4400BFFF,0xFF00BFFF);
                if (tracers.getValue()) RenderUtil.drawTracer(event.matrices,player.getPos(),0xFF00FF88);
            }
            if (crystals.getValue()&&entity instanceof EndCrystalEntity crystal)
                RenderUtil.drawBox(event.matrices,crystal.getBoundingBox(),0x44FF6600,0xFFFF6600);
        }
    }
}
EOF

cat > "$SRC/module/modules/visual/HUD.java" << 'EOF'
package dev.axiom.module.modules.visual;
import dev.axiom.AxiomClient;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.render.RenderTickCounter;
import net.minecraft.text.Text;
import java.awt.Color;
import java.util.*;
import java.util.stream.Collectors;
public class HUD extends Module {
    public final BooleanSetting arrayList   = register(new BooleanSetting("ArrayList",   true));
    public final BooleanSetting watermark   = register(new BooleanSetting("Watermark",   true));
    public final BooleanSetting coords      = register(new BooleanSetting("Coords",      true));
    public final BooleanSetting fps         = register(new BooleanSetting("FPS",         true));
    public final ModeSetting    colorMode   = register(new ModeSetting("Color Mode","Rainbow","Rainbow","Static","Fade"));
    public final NumberSetting  rainbowSpeed= register(new NumberSetting("Rainbow Speed",2.0,0.1,10));
    public HUD() { super("HUD","Vibecoded heads-up display",Category.VISUAL,-1); }
    @Override protected void onEnable() { HudRenderCallback.EVENT.register(this::onHudRender); }
    private void onHudRender(DrawContext ctx, RenderTickCounter counter) {
        if (mc.player==null) return;
        int screenW=mc.getWindow().getScaledWidth(); int y=2;
        if (watermark.getValue()) { ctx.drawTextWithShadow(mc.textRenderer,Text.of("§b§lAxiom §7§lClient"),2,y,0xFFFFFF); y+=10; }
        if (fps.getValue()) { ctx.drawTextWithShadow(mc.textRenderer,Text.of("§7FPS: §f"+mc.getCurrentFps()),2,y,0xFFFFFF); y+=10; }
        if (coords.getValue()) ctx.drawTextWithShadow(mc.textRenderer,Text.of(String.format("§7XYZ: §f%.0f §f%.0f §f%.0f",mc.player.getX(),mc.player.getY(),mc.player.getZ())),2,y,0xFFFFFF);
        if (arrayList.getValue()) {
            List<Module> enabled=AxiomClient.MODULE_MANAGER.getModules().stream().filter(Module::isEnabled).sorted(Comparator.comparing(m->m.name)).collect(Collectors.toList());
            int ay=2;
            for (int i=0;i<enabled.size();i++) {
                Module m=enabled.get(i); int color=getRainbowColor(i);
                int textW=mc.textRenderer.getWidth(m.name);
                ctx.drawTextWithShadow(mc.textRenderer,Text.of(m.name),screenW-textW-2,ay,color); ay+=10;
            }
        }
    }
    private int getRainbowColor(int index) {
        if (colorMode.getValue().equals("Static")) return 0x00BFFF;
        float hue=((System.currentTimeMillis()*rainbowSpeed.getValue()/5000f)+(index*0.1f))%1.0f;
        return Color.HSBtoRGB(hue,0.8f,1.0f);
    }
}
EOF

cat > "$SRC/module/modules/visual/ClickGUI.java" << 'EOF'
package dev.axiom.module.modules.visual;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
public class ClickGUI extends Module {
    public ClickGUI() { super("ClickGUI","Open the Axiom settings GUI (Right Shift)",Category.VISUAL,-1); }
}
EOF

# Cosmetics.java is large — write it in full
cat > "$SRC/module/modules/visual/Cosmetics.java" << 'EOF'
package dev.axiom.module.modules.visual;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventRender3D;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import net.minecraft.client.network.AbstractClientPlayerEntity;
import net.minecraft.client.render.*;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.math.Vec3d;
import org.joml.Matrix4f;
import org.joml.Quaternionf;
import java.awt.Color;
public class Cosmetics extends Module {
    public final BooleanSetting chinaHat       = register(new BooleanSetting("China Hat",       true));
    public final ModeSetting    hatStyle        = register(new ModeSetting("Hat Style","Bamboo","Bamboo","Oni","Straw","Pointy"));
    public final NumberSetting  hatSize         = register(new NumberSetting("Hat Size",   1.0,0.5,2.0));
    public final BooleanSetting hatRibbon       = register(new BooleanSetting("Hat Ribbon",     true));
    public final NumberSetting  ribbonHue       = register(new NumberSetting("Ribbon Hue", 180,0,360));
    public final BooleanSetting wings           = register(new BooleanSetting("Wings",          false));
    public final ModeSetting    wingStyle       = register(new ModeSetting("Wing Style","Feather","Feather","Demon","Butterfly","Crystal"));
    public final BooleanSetting wingFlap        = register(new BooleanSetting("Wing Flap",       true));
    public final NumberSetting  wingSpan        = register(new NumberSetting("Wing Span",  1.4,0.5,3.0));
    public final NumberSetting  wingFlapSpeed   = register(new NumberSetting("Flap Speed", 1.2,0.1,5.0));
    public final BooleanSetting wingGlow        = register(new BooleanSetting("Wing Glow",       true));
    public final BooleanSetting cape            = register(new BooleanSetting("Cape",           false));
    public final ModeSetting    capeStyle       = register(new ModeSetting("Cape Style","Gradient","Gradient","Solid","Animated","Pride"));
    public final NumberSetting  capeLength      = register(new NumberSetting("Cape Length",1.0,0.3,2.0));
    public final BooleanSetting trail           = register(new BooleanSetting("Trail",          false));
    public final ModeSetting    trailStyle      = register(new ModeSetting("Trail Style","Sparkle","Sparkle","Hearts","Stars","Flame","Rainbow"));
    public final NumberSetting  trailDensity    = register(new NumberSetting("Trail Density",2.0,0.5,5.0));
    public final ModeSetting    colorTheme      = register(new ModeSetting("Color Theme","Cyan","Cyan","Red","Purple","Gold","Rainbow","Custom"));
    public final NumberSetting  customHue       = register(new NumberSetting("Custom Hue",200,0,360));
    public final NumberSetting  colorSaturation = register(new NumberSetting("Saturation",0.8,0.0,1.0));
    public final NumberSetting  colorBrightness = register(new NumberSetting("Brightness",1.0,0.0,1.0));
    public final NumberSetting  glowAlpha       = register(new NumberSetting("Glow Alpha",0.35,0.0,1.0));
    public final BooleanSetting aspectOverride  = register(new BooleanSetting("Aspect Override", false));
    public final ModeSetting    aspectPreset    = register(new ModeSetting("Aspect Preset","16:9","16:9","4:3","21:9","1:1","Custom"));
    public final NumberSetting  aspectCustomW   = register(new NumberSetting("Custom W",16,1,32));
    public final NumberSetting  aspectCustomH   = register(new NumberSetting("Custom H",9,1,32));
    private float flapTimer = 0f;
    public Cosmetics() { super("Cosmetics","China hat, wings, cape, trails, color themes, aspect ratio",Category.VISUAL,-1); }
    @Subscribe public void onRender3D(EventRender3D event) {
        if (mc.world==null||mc.player==null) return;
        flapTimer += wingFlapSpeed.getValue().floatValue()*0.05f;
        Vec3d cam = mc.gameRenderer.getCamera().getPos();
        for (var entity:mc.world.getEntities()) {
            if (!(entity instanceof AbstractClientPlayerEntity player)) continue;
            MatrixStack mat=event.matrices; mat.push();
            mat.translate(player.getX()-cam.x, player.getY()-cam.y, player.getZ()-cam.z);
            mat.multiply(new Quaternionf().rotationY((float)Math.toRadians(-player.getYaw()+180f)));
            if (chinaHat.getValue()) renderHat(mat,player);
            if (wings.getValue())    renderWings(mat,player);
            if (cape.getValue())     renderCape(mat,player);
            if (trail.getValue())    renderTrail(mat,player,cam);
            mat.pop();
        }
    }
    private void renderHat(MatrixStack mat, AbstractClientPlayerEntity player) {
        mat.push(); mat.translate(0,1.85,0);
        float scale=hatSize.getValue().floatValue(); mat.scale(scale,scale,scale);
        int primary=getThemeColor(0), accent=getRibbonColor();
        switch(hatStyle.getValue()) {
            case "Bamboo"  -> renderBambooHat(mat,primary,accent);
            case "Oni"     -> renderOniHat(mat,primary,accent);
            case "Straw"   -> renderStrawHat(mat,primary,accent);
            case "Pointy"  -> renderPointyHat(mat,primary,accent);
        }
        mat.pop();
    }
    private void renderBambooHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.55f,8,primary,glowAlpha.getValue().floatValue());
        drawDisc(mat,0,0.02f,0,0.5f,8,primary,0.9f);
        drawCone(mat,0,0,0,0.25f,0.4f,10,primary);
        if(hatRibbon.getValue()) drawRing(mat,0,0.05f,0,0.26f,0.03f,accent);
    }
    private void renderOniHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.6f,10,primary,0.9f);
        drawCone(mat,0,0,0,0.28f,0.5f,10,primary);
        drawCone(mat,-0.15f,0.35f,0f,0.04f,0.15f,6,accent);
        drawCone(mat,0.15f,0.35f,0f,0.04f,0.15f,6,accent);
        if(hatRibbon.getValue()) drawRing(mat,0,0.06f,0,0.29f,0.025f,accent);
    }
    private void renderStrawHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.7f,12,primary,0.85f);
        drawHemisphere(mat,0,0,0,0.22f,8,primary);
        if(hatRibbon.getValue()) drawRing(mat,0,0.03f,0,0.23f,0.04f,accent);
    }
    private void renderPointyHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.4f,8,primary,0.9f);
        drawCone(mat,0,0,0,0.18f,0.75f,8,primary);
        if(hatRibbon.getValue()) drawRing(mat,0,0.04f,0,0.19f,0.03f,accent);
    }
    private void renderWings(MatrixStack mat,AbstractClientPlayerEntity player){
        mat.push(); mat.translate(0,1.2,0.15);
        float span=wingSpan.getValue().floatValue();
        float flap=wingFlap.getValue()?(float)(Math.sin(flapTimer)*0.35):0f;
        int col=getThemeColor(0); float alpha=wingGlow.getValue()?0.75f:0.95f;
        switch(wingStyle.getValue()){
            case "Feather"   -> renderFeatherWings(mat,span,flap,col,alpha);
            case "Demon"     -> renderDemonWings(mat,span,flap,col,alpha);
            case "Butterfly" -> renderButterflyWings(mat,span,flap,col,alpha);
            case "Crystal"   -> renderCrystalWings(mat,span,flap,col,alpha);
        }
        mat.pop();
    }
    private void renderFeatherWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2) for(int layer=0;layer<3;layer++){
            mat.push(); float lo=layer*0.07f;
            mat.translate(side*0.1f,-lo,0);
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(25+layer*18-flap*30))));
            drawWingQuad(mat,side,span*(1f-layer*0.15f),0.55f*(1f-layer*0.1f),col,alpha-layer*0.12f);
            mat.pop();
        }
    }
    private void renderDemonWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2){
            mat.push();
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(40-flap*35))));
            drawDemonMembrane(mat,side,span,col,alpha); mat.pop();
        }
    }
    private void renderButterflyWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2){
            mat.push(); mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(15-flap*20))));
            drawWingQuad(mat,side,span*0.9f,0.65f,col,alpha); mat.pop();
            mat.push(); mat.translate(side*0.05f,-0.3f,0);
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(35+flap*15))));
            drawWingQuad(mat,side,span*0.55f,0.35f,getThemeColor(1),alpha*0.85f); mat.pop();
        }
    }
    private void renderCrystalWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2) for(int shard=0;shard<4;shard++){
            mat.push();
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(20+shard*22-flap*25))));
            float hue=(getBaseHue()+shard*15f)%360f;
            int sc=Color.HSBtoRGB(hue/360f,colorSaturation.getValue().floatValue(),colorBrightness.getValue().floatValue());
            drawCrystalShard(mat,side,span*(0.18f-shard*0.02f),0.65f-shard*0.1f,sc,alpha); mat.pop();
        }
    }
    private void renderCape(MatrixStack mat,AbstractClientPlayerEntity player){
        mat.push(); mat.translate(0,1.55,0.15);
        float len=capeLength.getValue().floatValue(); long t=System.currentTimeMillis();
        switch(capeStyle.getValue()){
            case "Gradient" -> drawCapeGradient(mat,0.5f,len,getThemeColor(0),getThemeColor(1),0.85f);
            case "Solid"    -> drawCapeGradient(mat,0.5f,len,getThemeColor(0),getThemeColor(0),0.85f);
            case "Animated" -> { float hue=((t/2000f)%1f); int c=Color.HSBtoRGB(hue,colorSaturation.getValue().floatValue(),colorBrightness.getValue().floatValue()); drawCapeGradient(mat,0.5f,len,c,c,0.8f); }
            case "Pride"    -> drawPrideCape(mat,0.5f,len);
        }
        mat.pop();
    }
    private void renderTrail(MatrixStack mat,AbstractClientPlayerEntity player,Vec3d cam){
        int count=(int)(trailDensity.getValue()*4); long t=System.currentTimeMillis();
        for(int i=0;i<count;i++){
            mat.push();
            mat.translate((float)(Math.sin(t*0.004+i)*0.08),i*0.12f*0.3f,-i*0.12f);
            drawSprite(mat,0.06f*(1f-(float)i/count),getTrailColor(i,t),0.7f*(1f-(float)i/count));
            mat.pop();
        }
    }
    public float getAspectOverride(){
        if(!aspectOverride.getValue()) return -1f;
        return switch(aspectPreset.getValue()){
            case "16:9"->16f/9f; case "4:3"->4f/3f; case "21:9"->21f/9f; case "1:1"->1f;
            case "Custom"->aspectCustomW.getValue().floatValue()/aspectCustomH.getValue().floatValue();
            default->-1f;
        };
    }
    public int getThemeColor(int variant){
        float hue=getBaseHue();
        if(colorTheme.getValue().equals("Rainbow")) hue=((System.currentTimeMillis()*0.0003f)+variant*0.15f)%1f*360f;
        hue=(hue+variant*25f)%360f;
        return Color.HSBtoRGB(hue/360f,colorSaturation.getValue().floatValue(),colorBrightness.getValue().floatValue());
    }
    private float getBaseHue(){
        return switch(colorTheme.getValue()){ case "Cyan"->180f; case "Red"->0f; case "Purple"->280f; case "Gold"->45f; case "Custom"->customHue.getValue().floatValue(); default->180f; };
    }
    private int getRibbonColor(){ return Color.HSBtoRGB(ribbonHue.getValue().floatValue()/360f,0.85f,1f); }
    private int getTrailColor(int index,long t){
        return switch(trailStyle.getValue()){
            case "Rainbow"->Color.HSBtoRGB(((t*0.0005f+index*0.08f)%1f),0.9f,1f);
            case "Flame"->Color.HSBtoRGB(0.05f-index*0.005f,0.9f,1f-index*0.04f);
            default->getThemeColor(index%2);
        };
    }
    private void drawDisc(MatrixStack mat,float x,float y,float z,float radius,int segments,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_FAN,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,x,y,z).color(r,g,b,alpha);
        for(int i=0;i<=segments;i++){double a=2*Math.PI*i/segments; buf.vertex(m,x+(float)(Math.cos(a)*radius),y,z+(float)(Math.sin(a)*radius)).color(r,g,b,alpha);}
        tess.draw();
    }
    private void drawCone(MatrixStack mat,float x,float y,float z,float baseR,float height,int segments,int color){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_FAN,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,x,y+height,z).color(r,g,b,1f);
        for(int i=0;i<=segments;i++){double a=2*Math.PI*i/segments; buf.vertex(m,x+(float)(Math.cos(a)*baseR),y,z+(float)(Math.sin(a)*baseR)).color(r,g,b,0.9f);}
        tess.draw();
    }
    private void drawHemisphere(MatrixStack mat,float x,float y,float z,float radius,int rings,int color){
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        Tessellator tess=Tessellator.getInstance();
        for(int ring=0;ring<rings;ring++){
            float lat0=(float)(Math.PI/2*ring/rings),lat1=(float)(Math.PI/2*(ring+1)/rings);
            BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_STRIP,VertexFormats.POSITION_COLOR);
            for(int seg=0;seg<=10;seg++){double lon=2*Math.PI*seg/10;
                buf.vertex(m,x+(float)(Math.cos(lat0)*Math.cos(lon)*radius),y+(float)(Math.sin(lat0)*radius),z+(float)(Math.cos(lat0)*Math.sin(lon)*radius)).color(r,g,b,0.9f);
                buf.vertex(m,x+(float)(Math.cos(lat1)*Math.cos(lon)*radius),y+(float)(Math.sin(lat1)*radius),z+(float)(Math.cos(lat1)*Math.sin(lon)*radius)).color(r,g,b,0.9f);}
            tess.draw();
        }
    }
    private void drawRing(MatrixStack mat,float x,float y,float z,float radius,float thickness,int color){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_STRIP,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        for(int i=0;i<=16;i++){double a=2*Math.PI*i/16; float cx=x+(float)(Math.cos(a)*radius),cz=z+(float)(Math.sin(a)*radius);
            buf.vertex(m,cx,y,cz).color(r,g,b,1f); buf.vertex(m,cx,y+thickness,cz).color(r,g,b,0.6f);}
        tess.draw();
    }
    private void drawWingQuad(MatrixStack mat,int side,float w,float h,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,0,0,0).color(r,g,b,alpha); buf.vertex(m,side*w,0,0).color(r,g,b,alpha*0.4f);
        buf.vertex(m,side*w,h,0).color(r,g,b,alpha*0.3f); buf.vertex(m,0,h,0).color(r,g,b,alpha);
        tess.draw();
    }
    private void drawDemonMembrane(MatrixStack mat,int side,float span,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_FAN,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,0,0,0).color(r,g,b,alpha);
        buf.vertex(m,side*span,0.5f,0).color(r,g,b,alpha*0.5f);
        float[]xs={0.8f,0.65f,0.9f,0.5f},ys={0.1f,0.0f,-0.15f,-0.3f};
        for(int i=0;i<xs.length;i++) buf.vertex(m,side*span*xs[i],ys[i],0).color(r,g,b,alpha*0.6f);
        buf.vertex(m,0,-0.3f,0).color(r,g,b,alpha);
        tess.draw();
    }
    private void drawCrystalShard(MatrixStack mat,int side,float w,float h,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLES,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,0,0,0).color(r,g,b,alpha); buf.vertex(m,side*w,h*0.3f,0).color(r,g,b,alpha*0.5f); buf.vertex(m,side*w*0.6f,h,0).color(r,g,b,alpha*0.3f);
        tess.draw();
    }
    private void drawCapeGradient(MatrixStack mat,float w,float len,int topColor,int botColor,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float tr=((topColor>>16)&0xFF)/255f,tg=((topColor>>8)&0xFF)/255f,tb=(topColor&0xFF)/255f;
        float br=((botColor>>16)&0xFF)/255f,bg=((botColor>>8)&0xFF)/255f,bb=(botColor&0xFF)/255f;
        buf.vertex(m,-w,0,0.02f).color(tr,tg,tb,alpha); buf.vertex(m,w,0,0.02f).color(tr,tg,tb,alpha);
        buf.vertex(m,w,-len,0.02f).color(br,bg,bb,alpha*0.3f); buf.vertex(m,-w,-len,0.02f).color(br,bg,bb,alpha*0.3f);
        tess.draw();
    }
    private void drawPrideCape(MatrixStack mat,float w,float len){
        int[]stripes={0xE40303,0xFF8C00,0xFFED00,0x008026,0x004DFF,0x750787};
        float stripeH=len/stripes.length;
        Tessellator tess=Tessellator.getInstance();
        for(int i=0;i<stripes.length;i++){
            BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
            Matrix4f m=mat.peek().getPositionMatrix();
            float y0=-i*stripeH,y1=-(i+1)*stripeH;
            float r=((stripes[i]>>16)&0xFF)/255f,g=((stripes[i]>>8)&0xFF)/255f,b=(stripes[i]&0xFF)/255f;
            buf.vertex(m,-w,y0,0.02f).color(r,g,b,0.9f); buf.vertex(m,w,y0,0.02f).color(r,g,b,0.9f);
            buf.vertex(m,w,y1,0.02f).color(r,g,b,0.9f);  buf.vertex(m,-w,y1,0.02f).color(r,g,b,0.9f);
            tess.draw();
        }
    }
    private void drawSprite(MatrixStack mat,float size,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,-size,-size,0).color(r,g,b,alpha); buf.vertex(m,size,-size,0).color(r,g,b,alpha);
        buf.vertex(m,size,size,0).color(r,g,b,alpha);   buf.vertex(m,-size,size,0).color(r,g,b,alpha);
        tess.draw();
    }
}
EOF

cat > "$SRC/mixin/MixinMinecraftClient.java" << 'EOF'
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
EOF

cat > "$SRC/mixin/MixinGameRenderer.java" << 'EOF'
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
EOF

cat > "$SRC/gui/clicks/AxiomGUIScreen.java" << 'EOF'
package dev.axiom.gui.clicks;
import dev.axiom.AxiomClient;
import dev.axiom.module.Module;
import dev.axiom.module.Category;
import dev.axiom.setting.*;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;
import java.util.*;
import java.util.stream.Collectors;
public class AxiomGUIScreen extends Screen {
    private Category selectedCategory=Category.COMBAT;
    private Module selectedModule=null;
    private static final int SIDEBAR_W=110,MODULE_W=160,SETTING_W=200,ROW_H=20,PADDING=6;
    private Setting<?> dragging=null; private double dragStartX=0,dragStartVal=0;
    public AxiomGUIScreen(){ super(Text.of("Axiom")); }
    @Override public void render(DrawContext ctx,int mx,int my,float delta){
        ctx.fillGradient(0,0,width,height,0xCC0A0A14,0xCC0A0A14);
        renderSidebar(ctx,mx,my); renderModuleList(ctx,mx,my);
        if(selectedModule!=null) renderSettings(ctx,mx,my);
        ctx.drawTextWithShadow(client.textRenderer,Text.of("§b§lAxiom §8| §7Settings"),PADDING,PADDING,0xFFFFFF);
    }
    private void renderSidebar(DrawContext ctx,int mx,int my){
        int x=PADDING,y=24;
        for(Category cat:Category.values()){
            boolean sel=cat==selectedCategory;
            ctx.fill(x,y,x+SIDEBAR_W,y+ROW_H,sel?0xFF1E3A5F:0xFF111827);
            if(sel) ctx.fill(x,y,x+3,y+ROW_H,0xFF00BFFF);
            ctx.drawTextWithShadow(client.textRenderer,Text.of(cat.name()),x+8,y+6,sel?0xFF00BFFF:0xFF8899AA);
            y+=ROW_H+2;
        }
    }
    private void renderModuleList(DrawContext ctx,int mx,int my){
        int x=PADDING+SIDEBAR_W+4,y=24;
        for(Module m:AxiomClient.MODULE_MANAGER.getModules().stream().filter(mod->mod.category==selectedCategory).collect(Collectors.toList())){
            boolean sel=m==selectedModule;
            ctx.fill(x,y,x+MODULE_W,y+ROW_H,sel?0xFF1A2A3A:(m.isEnabled()?0xFF152235:0xFF111827));
            if(m.isEnabled()) ctx.fill(x,y,x+3,y+ROW_H,0xFF00BFFF);
            ctx.drawTextWithShadow(client.textRenderer,Text.of(m.name),x+8,y+6,m.isEnabled()?0xFF00BFFF:(sel?0xFFCCDDEE:0xFF8899AA));
            y+=ROW_H+2;
        }
    }
    private void renderSettings(DrawContext ctx,int mx,int my){
        int x=PADDING+SIDEBAR_W+MODULE_W+8,y=24;
        ctx.fill(x,y-2,x+SETTING_W,y+selectedModule.getSettings().size()*(ROW_H+2)+10,0xFF0D1520);
        ctx.drawTextWithShadow(client.textRenderer,Text.of("§f"+selectedModule.name),x+6,y,0xFFFFFF);
        y+=ROW_H;
        for(Setting<?> s:selectedModule.getSettings()){
            if(s instanceof BooleanSetting bs) renderToggle(ctx,x,y,bs,mx,my);
            else if(s instanceof NumberSetting ns) renderSlider(ctx,x,y,ns,mx,my);
            else if(s instanceof ModeSetting ms) renderMode(ctx,x,y,ms,mx,my);
            y+=ROW_H+2;
        }
    }
    private void renderToggle(DrawContext ctx,int x,int y,BooleanSetting s,int mx,int my){
        ctx.fill(x,y,x+SETTING_W,y+ROW_H,0xFF141E2B);
        ctx.drawTextWithShadow(client.textRenderer,Text.of(s.name),x+6,y+6,0xFFCCCCCC);
        boolean on=s.getValue(); int knobX=on?x+SETTING_W-20:x+SETTING_W-34;
        ctx.fill(x+SETTING_W-36,y+6,x+SETTING_W-4,y+14,on?0xFF00BFFF:0xFF334455);
        ctx.fill(knobX,y+4,knobX+14,y+16,0xFFFFFFFF);
    }
    private void renderSlider(DrawContext ctx,int x,int y,NumberSetting s,int mx,int my){
        ctx.fill(x,y,x+SETTING_W,y+ROW_H,0xFF141E2B);
        ctx.drawTextWithShadow(client.textRenderer,Text.of(s.name+": §f"+String.format("%.2f",s.getValue())),x+6,y+6,0xFFCCCCCC);
        int tx=x+6,ty=y+ROW_H-5,tw=SETTING_W-12;
        ctx.fill(tx,ty,tx+tw,ty+3,0xFF223344);
        float pct=(float)((s.getValue()-s.min)/(s.max-s.min));
        ctx.fill(tx,ty,tx+(int)(tw*pct),ty+3,0xFF00BFFF);
        int kx=tx+(int)(tw*pct)-3; ctx.fill(kx,ty-2,kx+6,ty+5,0xFFFFFFFF);
    }
    private void renderMode(DrawContext ctx,int x,int y,ModeSetting s,int mx,int my){
        ctx.fill(x,y,x+SETTING_W,y+ROW_H,0xFF141E2B);
        ctx.drawTextWithShadow(client.textRenderer,Text.of(s.name+": §b"+s.getValue()),x+6,y+6,0xFFCCCCCC);
        ctx.drawTextWithShadow(client.textRenderer,Text.of("§7▶"),x+SETTING_W-14,y+6,0xFF556677);
    }
    @Override public boolean mouseClicked(double mx,double my,int button){
        int sx=PADDING,sy=24;
        for(Category cat:Category.values()){
            if(mx>=sx&&mx<=sx+SIDEBAR_W&&my>=sy&&my<=sy+ROW_H){selectedCategory=cat;selectedModule=null;return true;}
            sy+=ROW_H+2;
        }
        int lx=PADDING+SIDEBAR_W+4,ly=24;
        for(Module m:AxiomClient.MODULE_MANAGER.getModules().stream().filter(mod->mod.category==selectedCategory).collect(Collectors.toList())){
            if(mx>=lx&&mx<=lx+MODULE_W&&my>=ly&&my<=ly+ROW_H){if(button==0)selectedModule=m;if(button==1)m.toggle();return true;}
            ly+=ROW_H+2;
        }
        if(selectedModule!=null){
            int settX=PADDING+SIDEBAR_W+MODULE_W+8,settY=24+ROW_H;
            for(Setting<?> s:selectedModule.getSettings()){
                if(my>=settY&&my<=settY+ROW_H){
                    if(s instanceof BooleanSetting bs&&mx>=settX+SETTING_W-36) bs.toggle();
                    else if(s instanceof ModeSetting ms&&button==0) ms.cycle();
                    else if(s instanceof NumberSetting ns){dragging=ns;dragStartX=mx;dragStartVal=ns.getValue();}
                    return true;
                }
                settY+=ROW_H+2;
            }
        }
        return super.mouseClicked(mx,my,button);
    }
    @Override public boolean mouseDragged(double mx,double my,int button,double dx,double dy){
        if(dragging instanceof NumberSetting ns){ns.setValue(dragStartVal+(mx-dragStartX)*(ns.max-ns.min)/(SETTING_W-12));return true;}
        return super.mouseDragged(mx,my,button,dx,dy);
    }
    @Override public boolean mouseReleased(double mx,double my,int button){dragging=null;return super.mouseReleased(mx,my,button);}
    @Override public boolean shouldPause(){return false;}
}
EOF

# ── gradlew stub (tells people to download the real one) ──────────────────
cat > "$ROOT/GET_GRADLEW.txt" << 'EOF'
The gradlew and gradlew.bat files must be downloaded from a Fabric template project.
Fastest way:
  1. Go to https://fabricmc.net/develop/template/
  2. Download the template zip, copy gradlew + gradlew.bat + gradle/ into this folder
  3. Then run: ./gradlew build
EOF

echo ""
echo "✅  Axiom Client source tree created in ./$ROOT"
echo "Next steps:"
echo "  1. cd $ROOT"
echo "  2. Copy gradlew/gradlew.bat from https://fabricmc.net/develop/template/"
echo "  3. ./gradlew build"
echo "  4. Grab build/libs/axiom-client-1.0.0.jar"
