#include "MHVehiclePawn.h"

#include "ChaosVehicleMovementComponent.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "MHPedestrianCharacter.h"
#include "MHWantedSubsystem.h"

AMHVehiclePawn::AMHVehiclePawn()
{
    PrimaryActorTick.bCanEverTick = false;
    ApplyHeavyVehicleTuning();
}

void AMHVehiclePawn::ApplyHeavyVehicleTuning()
{
    if (UChaosVehicleMovementComponent* Movement = GetVehicleMovementComponent())
    {
        Movement->Mass = VehicleMassKg;
        Movement->DragCoefficient = DragCoefficient;
    }
}

bool AMHVehiclePawn::CanDriverEnter(const APawn* CandidateDriver) const
{
    if (CandidateDriver == nullptr)
    {
        return false;
    }

    const float EntryRadiusUnrealUnits = EntryRadiusMeters * 100.0f;
    return FVector::DistSquared(CandidateDriver->GetActorLocation(), GetActorLocation()) <= FMath::Square(EntryRadiusUnrealUnits);
}

FVector AMHVehiclePawn::GetSuggestedExitLocation() const
{
    return GetActorLocation() + (GetActorRightVector() * 175.0f) + FVector(0.0f, 0.0f, 20.0f);
}

void AMHVehiclePawn::NotifyHit(
    UPrimitiveComponent* MyComp,
    AActor* Other,
    UPrimitiveComponent* OtherComp,
    bool bSelfMoved,
    FVector HitLocation,
    FVector HitNormal,
    FVector NormalImpulse,
    const FHitResult& Hit)
{
    Super::NotifyHit(MyComp, Other, OtherComp, bSelfMoved, HitLocation, HitNormal, NormalImpulse, Hit);

    if (bWrecked || VehicleMassKg <= 0.0f)
    {
        return;
    }

    const float ImpactSpeed = NormalImpulse.Size() / VehicleMassKg;
    if (ImpactSpeed <= CollisionDamageThreshold)
    {
        return;
    }

    const float Damage = (ImpactSpeed - CollisionDamageThreshold) * CollisionDamageScale;
    ApplyVehicleDamage(Damage);

    const bool bHitAnotherActor = Other != nullptr && Other != this && Other->IsA<APawn>();
    if (bHitAnotherActor)
    {
        if (UWorld* World = GetWorld())
        {
            if (UMHWantedSubsystem* Wanted = World->GetSubsystem<UMHWantedSubsystem>())
            {
                const int32 Severity = FMath::Clamp(FMath::RoundToInt(Damage * 0.5f), 1, 20);
                const bool bHitPedestrian = Other->IsA<AMHPedestrianCharacter>();
                Wanted->ReportCrime(bHitPedestrian ? EMHCrimeType::Assault : EMHCrimeType::PropertyDamage, Severity);
            }
        }
    }
}

void AMHVehiclePawn::ApplyVehicleDamage(float Damage)
{
    if (bWrecked || Damage <= 0.0f)
    {
        return;
    }

    Health = FMath::Clamp(Health - Damage, 0.0f, MaxHealth);
    if (Health <= 0.0f)
    {
        bWrecked = true;
        if (UChaosVehicleMovementComponent* Movement = GetVehicleMovementComponent())
        {
            Movement->SetThrottleInput(0.0f);
            Movement->SetHandbrakeInput(true);
        }
    }

    OnVehicleHealthChanged.Broadcast(GetHealthPercent(), bWrecked);
}

void AMHVehiclePawn::RepairVehicle()
{
    Health = MaxHealth;
    bWrecked = false;

    if (UChaosVehicleMovementComponent* Movement = GetVehicleMovementComponent())
    {
        Movement->SetHandbrakeInput(false);
    }

    OnVehicleHealthChanged.Broadcast(GetHealthPercent(), bWrecked);
}

float AMHVehiclePawn::GetHealthPercent() const
{
    return MaxHealth > 0.0f ? Health / MaxHealth : 0.0f;
}
