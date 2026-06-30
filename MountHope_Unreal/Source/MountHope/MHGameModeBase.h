#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "MHGameModeBase.generated.h"

class AMHMissionTriggerActor;
struct FMHMissionStep;

UCLASS()
class MOUNTHOPE_API AMHGameModeBase : public AGameModeBase
{
    GENERATED_BODY()

public:
    AMHGameModeBase();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool CompleteCurrentObjective(bool bPlayerInVehicle);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool TryCompleteVehicleObjective(bool bPlayerInVehicle);

protected:
    UPROPERTY(Transient)
    TObjectPtr<AMHMissionTriggerActor> ObjectiveTrigger = nullptr;

private:
    bool IsWorldTargetObjective(const FMHMissionStep& Step) const;
    void RefreshObjectiveTrigger();
};
