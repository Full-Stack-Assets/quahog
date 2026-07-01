#include "MHPoliceSpawnerActor.h"

#include "Kismet/GameplayStatics.h"
#include "MHPoliceUnitPawn.h"
#include "MHWantedSubsystem.h"
#include "TimerManager.h"

AMHPoliceSpawnerActor::AMHPoliceSpawnerActor()
{
    PrimaryActorTick.bCanEverTick = false;
    PoliceUnitClass = AMHPoliceUnitPawn::StaticClass();
}

void AMHPoliceSpawnerActor::BeginPlay()
{
    Super::BeginPlay();
    GetWorldTimerManager().SetTimer(
        ManageTimerHandle,
        this,
        &AMHPoliceSpawnerActor::ManagePoliceUnits,
        TickIntervalSeconds,
        true);
}

int32 AMHPoliceSpawnerActor::GetDesiredUnitCount() const
{
    const UWorld* World = GetWorld();
    const UMHWantedSubsystem* WantedSubsystem = World ? World->GetSubsystem<UMHWantedSubsystem>() : nullptr;
    return WantedSubsystem ? FMath::Min(WantedSubsystem->GetWantedLevel(), 5) : 0;
}

void AMHPoliceSpawnerActor::ManagePoliceUnits()
{
    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn || !PoliceUnitClass)
    {
        return;
    }

    const FVector PlayerLocation = PlayerPawn->GetActorLocation();
    const float DespawnDistanceUnrealUnits = DespawnDistanceMeters * 100.0f;

    for (int32 Index = ActiveUnits.Num() - 1; Index >= 0; --Index)
    {
        AMHPoliceUnitPawn* Unit = ActiveUnits[Index];
        if (!IsValid(Unit))
        {
            ActiveUnits.RemoveAt(Index);
            continue;
        }

        if (FVector::DistSquared(PlayerLocation, Unit->GetActorLocation()) > FMath::Square(DespawnDistanceUnrealUnits))
        {
            Unit->Destroy();
            ActiveUnits.RemoveAt(Index);
        }
    }

    const int32 DesiredCount = GetDesiredUnitCount();

    while (ActiveUnits.Num() > DesiredCount)
    {
        const int32 LastIndex = ActiveUnits.Num() - 1;
        if (AMHPoliceUnitPawn* Unit = ActiveUnits[LastIndex])
        {
            Unit->Destroy();
        }
        ActiveUnits.RemoveAt(LastIndex);
    }

    const float SpawnDistanceUnrealUnits = SpawnDistanceMeters * 100.0f;
    while (ActiveUnits.Num() < DesiredCount)
    {
        const float Angle = FMath::FRandRange(0.0f, 2.0f * PI);
        const FVector Offset = FVector(FMath::Cos(Angle), FMath::Sin(Angle), 0.0f) * SpawnDistanceUnrealUnits;
        const FVector SpawnLocation = PlayerLocation + Offset;

        AMHPoliceUnitPawn* NewUnit = GetWorld()->SpawnActor<AMHPoliceUnitPawn>(
            PoliceUnitClass,
            SpawnLocation,
            FRotator::ZeroRotator);

        if (!NewUnit)
        {
            break;
        }
        ActiveUnits.Add(NewUnit);
    }
}
