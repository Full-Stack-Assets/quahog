#include "MHPlayerController.h"

#include "Blueprint/UserWidget.h"
#include "MHGameHudWidget.h"
#include "MHGameStateSubsystem.h"

AMHPlayerController::AMHPlayerController()
{
    bShowMouseCursor = false;
}

void AMHPlayerController::BeginPlay()
{
    Super::BeginPlay();
    CreateHudWidget();
}

void AMHPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();

    if (InputComponent)
    {
        InputComponent->BindKey(EKeys::Period, IE_Pressed, this, &AMHPlayerController::DebugCycleWeather);
    }
}

void AMHPlayerController::PlayerTick(float DeltaTime)
{
    Super::PlayerTick(DeltaTime);

    StatusRefreshAccumulator += DeltaTime;
    if (HudWidget && StatusRefreshAccumulator >= 0.5f)
    {
        StatusRefreshAccumulator = 0.0f;
        HudWidget->RefreshHud();
    }
}

void AMHPlayerController::CreateHudWidget()
{
    if (HudWidget)
    {
        return;
    }

    TSubclassOf<UMHGameHudWidget> WidgetClass = HudWidgetClass;
    if (!WidgetClass)
    {
        WidgetClass = UMHGameHudWidget::StaticClass();
    }

    HudWidget = CreateWidget<UMHGameHudWidget>(this, WidgetClass);
    if (HudWidget)
    {
        HudWidget->AddToViewport(0);
    }
}

void AMHPlayerController::DebugCycleWeather()
{
    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
        {
            GameState->CycleWeather();
            if (HudWidget)
            {
                HudWidget->RefreshHud();
            }
        }
    }
}
