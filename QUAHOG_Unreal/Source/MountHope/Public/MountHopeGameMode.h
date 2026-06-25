#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "MountHopeGameMode.generated.h"

UCLASS()
class MOUNTHOPE_API AMountHopeGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    AMountHopeGameMode();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category = "MountHope|Mission")
    bool CompleteCurrentObjective(bool bPlayerInVehicle);
};
