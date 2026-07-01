#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHPedestrianSpawnerActor.generated.h"

class AMHPedestrianCharacter;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHPedestrianSpawnerActor : public AActor
{
    GENERATED_BODY()

public:
    AMHPedestrianSpawnerActor();

protected:
    virtual void BeginPlay() override;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    TSubclassOf<AMHPedestrianCharacter> PedestrianClass;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    int32 MaxActivePedestrians = 12;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float SpawnRadiusMeters = 35.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float DespawnRadiusMeters = 55.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float MinSpawnDistanceMeters = 15.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float TickIntervalSeconds = 2.0f;

private:
    void ManagePedestrians();
    void DespawnFarPedestrians(const FVector& PlayerLocation);
    void SpawnIfNeeded(const FVector& PlayerLocation);

    UPROPERTY(Transient)
    TArray<TObjectPtr<AMHPedestrianCharacter>> SpawnedPedestrians;

    FTimerHandle ManageTimerHandle;
};
