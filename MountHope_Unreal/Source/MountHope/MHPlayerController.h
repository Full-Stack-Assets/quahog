#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "MHPlayerController.generated.h"

class UMHGameHudWidget;

UCLASS()
class MOUNTHOPE_API AMHPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    AMHPlayerController();

    virtual void BeginPlay() override;
    virtual void SetupInputComponent() override;
    virtual void PlayerTick(float DeltaTime) override;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|HUD")
    UMHGameHudWidget* GetHudWidget() const { return HudWidget; }

protected:
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|HUD")
    TSubclassOf<UMHGameHudWidget> HudWidgetClass;

    UPROPERTY(BlueprintReadOnly, Category = "Mount Hope|HUD")
    TObjectPtr<UMHGameHudWidget> HudWidget;

private:
    void CreateHudWidget();
    void DebugCycleWeather();

    float StatusRefreshAccumulator = 0.0f;
};
