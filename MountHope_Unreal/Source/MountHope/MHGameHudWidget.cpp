#include "MHGameHudWidget.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Overlay.h"
#include "Components/OverlaySlot.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "MHDialogueSubsystem.h"
#include "MHGameStateSubsystem.h"
#include "MHMissionSubsystem.h"

namespace
{
UTextBlock* MakeHudTextBlock(UWidgetTree* Tree, const FName& Name, int32 FontSize, const FLinearColor& Color)
{
    UTextBlock* TextBlock = Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), Name);
    FSlateFontInfo FontInfo = TextBlock->GetFont();
    FontInfo.Size = FontSize;
    TextBlock->SetFont(FontInfo);
    TextBlock->SetColorAndOpacity(FSlateColor(Color));
    TextBlock->SetShadowOffset(FVector2D(1.0f, 1.0f));
    TextBlock->SetShadowColorAndOpacity(FLinearColor(0.0f, 0.0f, 0.0f, 0.85f));
    return TextBlock;
}
}

void UMHGameHudWidget::NativeConstruct()
{
    Super::NativeConstruct();
    EnsureWidgetTreeBuilt();
    BindSubsystemDelegates();
    RefreshObjectiveAndStatus();
}

void UMHGameHudWidget::NativeDestruct()
{
    UnbindSubsystemDelegates();
    Super::NativeDestruct();
}

void UMHGameHudWidget::EnsureWidgetTreeBuilt()
{
    if (ObjectiveTextBlock && DialogueLineTextBlock)
    {
        return;
    }

    if (!WidgetTree)
    {
        return;
    }

    RootOverlay = WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), TEXT("RootOverlay"));
    WidgetTree->RootWidget = RootOverlay;

    ObjectiveTextBlock = MakeHudTextBlock(WidgetTree, TEXT("ObjectiveText"), 20, FLinearColor(0.92f, 0.95f, 1.0f));
    if (UOverlaySlot* ObjectiveSlot = RootOverlay->AddChildToOverlay(ObjectiveTextBlock))
    {
        ObjectiveSlot->SetHorizontalAlignment(HAlign_Left);
        ObjectiveSlot->SetVerticalAlignment(VAlign_Top);
        ObjectiveSlot->SetPadding(FMargin(36.0f, 28.0f, 36.0f, 0.0f));
    }

    StatusTextBlock = MakeHudTextBlock(WidgetTree, TEXT("StatusText"), 16, FLinearColor(0.75f, 0.82f, 0.88f));
    if (UOverlaySlot* StatusSlot = RootOverlay->AddChildToOverlay(StatusTextBlock))
    {
        StatusSlot->SetHorizontalAlignment(HAlign_Right);
        StatusSlot->SetVerticalAlignment(VAlign_Top);
        StatusSlot->SetPadding(FMargin(0.0f, 28.0f, 36.0f, 0.0f));
    }

    DialogueBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("DialogueBox"));
    SpeakerTextBlock = MakeHudTextBlock(WidgetTree, TEXT("SpeakerText"), 22, FLinearColor(0.55f, 0.85f, 1.0f));
    DialogueLineTextBlock = MakeHudTextBlock(WidgetTree, TEXT("DialogueLineText"), 20, FLinearColor::White);

    if (UVerticalBoxSlot* SpeakerSlot = DialogueBox->AddChildToVerticalBox(SpeakerTextBlock))
    {
        SpeakerSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 6.0f));
    }
    DialogueBox->AddChildToVerticalBox(DialogueLineTextBlock);

    if (UOverlaySlot* DialogueSlot = RootOverlay->AddChildToOverlay(DialogueBox))
    {
        DialogueSlot->SetHorizontalAlignment(HAlign_Center);
        DialogueSlot->SetVerticalAlignment(VAlign_Bottom);
        DialogueSlot->SetPadding(FMargin(48.0f, 0.0f, 48.0f, 72.0f));
    }

    DialogueBox->SetVisibility(ESlateVisibility::Collapsed);
}

void UMHGameHudWidget::BindSubsystemDelegates()
{
    if (bDelegatesBound)
    {
        return;
    }

    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    if (UMHDialogueSubsystem* DialogueSubsystem = GameInstance->GetSubsystem<UMHDialogueSubsystem>())
    {
        DialogueSubsystem->OnDialogueLineChanged.AddDynamic(this, &UMHGameHudWidget::HandleDialogueLineChanged);
        DialogueSubsystem->OnDialogueEnded.AddDynamic(this, &UMHGameHudWidget::HandleDialogueEnded);
    }

    bDelegatesBound = true;
}

void UMHGameHudWidget::UnbindSubsystemDelegates()
{
    if (!bDelegatesBound)
    {
        return;
    }

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHDialogueSubsystem* DialogueSubsystem = GameInstance->GetSubsystem<UMHDialogueSubsystem>())
        {
            DialogueSubsystem->OnDialogueLineChanged.RemoveDynamic(this, &UMHGameHudWidget::HandleDialogueLineChanged);
            DialogueSubsystem->OnDialogueEnded.RemoveDynamic(this, &UMHGameHudWidget::HandleDialogueEnded);
        }
    }

    bDelegatesBound = false;
}

void UMHGameHudWidget::RefreshObjectiveAndStatus()
{
    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    FText Objective = FText::FromString(TEXT("Explore the waterfront."));
    if (UMHMissionSubsystem* MissionSubsystem = GameInstance->GetSubsystem<UMHMissionSubsystem>())
    {
        FMHMissionStep Step;
        if (MissionSubsystem->GetCurrentStep(Step))
        {
            Objective = FText::FromString(Step.Text);
        }
        else if (MissionSubsystem->bCampaignComplete)
        {
            Objective = FText::FromString(TEXT("Campaign complete."));
        }
    }

    SetObjectiveText(Objective);

    FString StatusString = TEXT("Cash: $0  |  Weather: Clear");
    if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
    {
        FString WeatherLabel;
        switch (GameState->Weather)
        {
        case EMHWeatherState::DenseFog:
            WeatherLabel = TEXT("Dense fog");
            break;
        case EMHWeatherState::CoastalRain:
            WeatherLabel = TEXT("Coastal rain");
            break;
        case EMHWeatherState::Noreaster:
            WeatherLabel = TEXT("Nor'easter");
            break;
        default:
            WeatherLabel = TEXT("Clear");
            break;
        }

        StatusString = FString::Printf(
            TEXT("Cash: $%d  |  Weather: %s"),
            GameState->Cash,
            *WeatherLabel);
    }

    SetStatusText(FText::FromString(StatusString));
}

void UMHGameHudWidget::RefreshHud()
{
    RefreshObjectiveAndStatus();
}

void UMHGameHudWidget::SetDialogueLine(const FText& Speaker, const FText& Line)
{
    if (DialogueBox)
    {
        DialogueBox->SetVisibility(ESlateVisibility::HitTestInvisible);
    }

    SetTextBlockContent(SpeakerTextBlock, FText::Format(FText::FromString(TEXT("{0}")), Speaker), false);
    SetTextBlockContent(DialogueLineTextBlock, Line, false);
}

void UMHGameHudWidget::ClearDialogue()
{
    SetTextBlockContent(SpeakerTextBlock, FText::GetEmpty(), true);
    SetTextBlockContent(DialogueLineTextBlock, FText::GetEmpty(), true);
    if (DialogueBox)
    {
        DialogueBox->SetVisibility(ESlateVisibility::Collapsed);
    }

    RefreshObjectiveAndStatus();
}

void UMHGameHudWidget::SetObjectiveText(const FText& Objective)
{
    SetTextBlockContent(ObjectiveTextBlock, Objective, false);
}

void UMHGameHudWidget::SetStatusText(const FText& Status)
{
    SetTextBlockContent(StatusTextBlock, Status, false);
}

void UMHGameHudWidget::HandleDialogueLineChanged(FName ConversationId, FName Speaker, FText LineText)
{
    SetDialogueLine(FText::FromName(Speaker), LineText);
}

void UMHGameHudWidget::HandleDialogueEnded(FName ConversationId)
{
    ClearDialogue();
}

void UMHGameHudWidget::SetTextBlockContent(UTextBlock* TextBlock, const FText& Content, bool bCollapseWhenEmpty)
{
    if (!TextBlock)
    {
        return;
    }

    TextBlock->SetText(Content);
    TextBlock->SetVisibility(
        Content.IsEmpty() && bCollapseWhenEmpty ? ESlateVisibility::Collapsed : ESlateVisibility::HitTestInvisible);
}
