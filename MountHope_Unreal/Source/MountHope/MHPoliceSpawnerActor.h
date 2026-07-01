#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHPoliceSpawnerActor.generated.h"

class AMHPoliceUnitPawn;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHPoliceSpawnerActor : public AActor
{
    GENERATED_BODY()

public:
    AMHPoliceSpawnerActor();

protected:
    virtual void BeginPlay() override;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    TSubclassOf<AMHPoliceUnitPawn> PoliceUnitClass;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float SpawnDistanceMeters = 45.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float DespawnDistanceMeters = 80.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float TickIntervalSeconds = 2.0f;

private:
    void ManagePoliceUnits();
    int32 GetDesiredUnitCount() const;

    UPROPERTY(Transient)
    TArray<TObjectPtr<AMHPoliceUnitPawn>> ActiveUnits;

    FTimerHandle ManageTimerHandle;
};
