#include "MHPedestrianSpawnerActor.h"

#include "Kismet/GameplayStatics.h"
#include "MHPedestrianCharacter.h"
#include "NavigationSystem.h"
#include "TimerManager.h"

AMHPedestrianSpawnerActor::AMHPedestrianSpawnerActor()
{
    PrimaryActorTick.bCanEverTick = false;
    PedestrianClass = AMHPedestrianCharacter::StaticClass();
}

void AMHPedestrianSpawnerActor::BeginPlay()
{
    Super::BeginPlay();
    GetWorldTimerManager().SetTimer(
        ManageTimerHandle,
        this,
        &AMHPedestrianSpawnerActor::ManagePedestrians,
        TickIntervalSeconds,
        true);
}

void AMHPedestrianSpawnerActor::ManagePedestrians()
{
    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn)
    {
        return;
    }

    const FVector PlayerLocation = PlayerPawn->GetActorLocation();
    DespawnFarPedestrians(PlayerLocation);
    SpawnIfNeeded(PlayerLocation);
}

void AMHPedestrianSpawnerActor::DespawnFarPedestrians(const FVector& PlayerLocation)
{
    const float DespawnRadiusUnrealUnits = DespawnRadiusMeters * 100.0f;

    for (int32 Index = SpawnedPedestrians.Num() - 1; Index >= 0; --Index)
    {
        AMHPedestrianCharacter* Pedestrian = SpawnedPedestrians[Index];
        if (!IsValid(Pedestrian))
        {
            SpawnedPedestrians.RemoveAt(Index);
            continue;
        }

        if (FVector::DistSquared(PlayerLocation, Pedestrian->GetActorLocation()) > FMath::Square(DespawnRadiusUnrealUnits))
        {
            Pedestrian->Destroy();
            SpawnedPedestrians.RemoveAt(Index);
        }
    }
}

void AMHPedestrianSpawnerActor::SpawnIfNeeded(const FVector& PlayerLocation)
{
    if (!PedestrianClass || !GetWorld() || SpawnedPedestrians.Num() >= MaxActivePedestrians)
    {
        return;
    }

    UNavigationSystemV1* NavSystem = UNavigationSystemV1::GetCurrent(GetWorld());
    if (!NavSystem)
    {
        return;
    }

    const float SpawnRadiusUnrealUnits = SpawnRadiusMeters * 100.0f;
    const float MinSpawnDistanceUnrealUnits = MinSpawnDistanceMeters * 100.0f;

    for (int32 Attempt = 0; Attempt < 5 && SpawnedPedestrians.Num() < MaxActivePedestrians; ++Attempt)
    {
        FNavLocation ResultLocation;
        if (!NavSystem->GetRandomReachablePointInRadius(PlayerLocation, SpawnRadiusUnrealUnits, ResultLocation))
        {
            continue;
        }

        if (FVector::DistSquared(PlayerLocation, ResultLocation.Location) < FMath::Square(MinSpawnDistanceUnrealUnits))
        {
            continue;
        }

        if (AMHPedestrianCharacter* NewPedestrian = GetWorld()->SpawnActor<AMHPedestrianCharacter>(
            PedestrianClass,
            ResultLocation.Location,
            FRotator::ZeroRotator))
        {
            SpawnedPedestrians.Add(NewPedestrian);
        }
    }
}
