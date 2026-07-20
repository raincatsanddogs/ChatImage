package io.github.kituin.chatimage.gui;

import it.unimi.dsi.fastutil.booleans.BooleanConsumer;
import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.components.Renderable;
import net.minecraft.client.gui.components.events.GuiEventListener;
import net.minecraft.client.gui.narration.NarratableEntry;
import net.minecraft.client.gui.screens.ConfirmScreen;
import net.minecraft.network.chat.CommonComponents;
import net.minecraft.network.chat.Component;

import static io.github.kituin.chatimage.tool.SimpleUtil.*;

@Environment(EnvType.CLIENT)
public class ConfirmNsfwScreen extends ConfirmScreen {

    public ConfirmNsfwScreen(BooleanConsumer callback, String link) {
        this(callback, createTranslatableComponent("nsfw.chatimage.open"), createLiteralComponent(link));
    }

    public ConfirmNsfwScreen(BooleanConsumer callback, Component title, Component message) {
        super(callback, title, message);
// IF fabric-1.16.5 || fabric-1.18.2
//        this.yesTranslated = ScreenTexts.YES;
//        this.noTranslated = ScreenTexts.NO;
// ELSE
        this.yesButtonComponent = CommonComponents.GUI_YES;
        this.noButtonComponent = CommonComponents.GUI_NO;
// END IF
    }

//IF <= fabric-1.19.4
//    public void render(MatrixStack matrices, int mouseX, int mouseY, float delta) {
//        super.render(matrices, mouseX, mouseY, delta);
//        drawCenteredTextWithShadow(matrices, this.textRenderer, createTranslatableComponent("nsfw.chatimage.warning"), this.width / 2, 110, 16764108);
//    }
// ELSE
    public void extractRenderState(GuiGraphicsExtractor graphics, int mouseX, int mouseY, float delta) {
        super.extractRenderState(graphics, mouseX, mouseY, delta);
        graphics.centeredText(this.font, createTranslatableComponent("nsfw.chatimage.warning"), this.width / 2, 110, 16764108);
    }
// END IF
// IF fabric-1.16.5
//    public <T extends ClickableWidget> T addDrawableWeight(T element)
//    {
//        return this.addButton(element);
// ELSE
    public <T extends GuiEventListener & Renderable & NarratableEntry> T addDrawableWeight(T element)
    {
        return this.addRenderableWidget(element);
// END IF
    }
}
