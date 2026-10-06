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
