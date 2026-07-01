#include "MHPedestrianCharacter.h"

#include "AIController.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "MHVehiclePawn.h"
#include "NavigationSystem.h"
#include "TimerManager.h"

AMHPedestrianCharacter::AMHPedestrianCharacter()
{
    PrimaryActorTick.bCanEverTick = true;
    AIControllerClass = AAIController::StaticClass();
    AutoPossessAI = EAutoPossessAI::PlacedInWorldOrSpawned;

    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->MaxWalkSpeed = NormalWalkSpeed;
}

void AMHPedestrianCharacter::BeginPlay()
{
    Super::BeginPlay();

    HomeLocation = GetActorLocation();
    GetCharacterMovement()->MaxWalkSpeed = NormalWalkSpeed;
    ScheduleNextWander();
}

void AMHPedestrianCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (AActor* Threat = FindNearestThreat())
    {
        FleeFromThreat(Threat);
    }
    else if (bIsFleeing)
    {
        bIsFleeing = false;
        GetCharacterMovement()->MaxWalkSpeed = NormalWalkSpeed;
        ScheduleNextWander();
    }
}

void AMHPedestrianCharacter::ScheduleNextWander()
{
    const float Interval = FMath::FRandRange(MinWanderIntervalSeconds, MaxWanderIntervalSeconds);
    GetWorldTimerManager().SetTimer(WanderTimerHandle, this, &AMHPedestrianCharacter::PickNewWanderTarget, Interval, false);
}

void AMHPedestrianCharacter::PickNewWanderTarget()
{
    if (bIsFleeing)
    {
        return;
    }

    if (UNavigationSystemV1* NavSystem = GetWorld() ? UNavigationSystemV1::GetCurrent(GetWorld()) : nullptr)
    {
        FNavLocation ResultLocation;
        const float RadiusUnrealUnits = WanderRadiusMeters * 100.0f;
        if (NavSystem->GetRandomReachablePointInRadius(HomeLocation, RadiusUnrealUnits, ResultLocation))
        {
            if (AAIController* PedController = Cast<AAIController>(GetController()))
            {
                PedController->MoveToLocation(ResultLocation.Location);
            }
        }
    }

    ScheduleNextWander();
}

AActor* AMHPedestrianCharacter::FindNearestThreat() const
{
    if (!GetWorld())
    {
        return nullptr;
    }

    const float RadiusUnrealUnits = ThreatDetectionRadiusMeters * 100.0f;
    TArray<AActor*> Vehicles;
    UGameplayStatics::GetAllActorsOfClass(GetWorld(), AMHVehiclePawn::StaticClass(), Vehicles);

    for (AActor* VehicleActor : Vehicles)
    {
        AMHVehiclePawn* Vehicle = Cast<AMHVehiclePawn>(VehicleActor);
        if (!Vehicle)
        {
            continue;
        }

        const float DistSq = FVector::DistSquared(GetActorLocation(), Vehicle->GetActorLocation());
        if (DistSq > FMath::Square(RadiusUnrealUnits))
        {
            continue;
        }

        if (Vehicle->GetVelocity().Size() >= ThreatSpeedThreshold)
        {
            return Vehicle;
        }
    }

    return nullptr;
}

void AMHPedestrianCharacter::FleeFromThreat(const AActor* Threat)
{
    if (!Threat)
    {
        return;
    }

    bIsFleeing = true;
    GetCharacterMovement()->MaxWalkSpeed = FleeSpeed;

    const FVector FleeDirection = (GetActorLocation() - Threat->GetActorLocation()).GetSafeNormal();
    const FVector FleeTarget = GetActorLocation() + FleeDirection * 800.0f;

    if (AAIController* PedController = Cast<AAIController>(GetController()))
    {
        PedController->MoveToLocation(FleeTarget);
    }
}
