#include "MHMissionTriggerActor.h"

#include "Components/SphereComponent.h"
#include "MHGameModeBase.h"
#include "MHVehiclePawn.h"

AMHMissionTriggerActor::AMHMissionTriggerActor()
{
    PrimaryActorTick.bCanEverTick = false;

    TriggerSphere = CreateDefaultSubobject<USphereComponent>(TEXT("TriggerSphere"));
    RootComponent = TriggerSphere;
    TriggerSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    TriggerSphere->SetCollisionResponseToAllChannels(ECR_Overlap);
    TriggerSphere->SetSphereRadius(350.0f);
}

void AMHMissionTriggerActor::SetTriggerRadius(float NewRadius)
{
    TriggerSphere->SetSphereRadius(FMath::Max(1.0f, NewRadius));
}

void AMHMissionTriggerActor::ResetConsumed()
{
    bConsumed = false;
}

void AMHMissionTriggerActor::BeginPlay()
{
    Super::BeginPlay();
    TriggerSphere->OnComponentBeginOverlap.AddDynamic(this, &AMHMissionTriggerActor::OnTriggerOverlap);
}

void AMHMissionTriggerActor::OnTriggerOverlap(
    UPrimitiveComponent* OverlappedComponent,
    AActor* OtherActor,
    UPrimitiveComponent* OtherComp,
    int32 OtherBodyIndex,
    bool bFromSweep,
    const FHitResult& SweepResult)
{
    if (bConsumed || !OtherActor)
    {
        return;
    }

    AMHGameModeBase* GameMode = GetWorld() ? Cast<AMHGameModeBase>(GetWorld()->GetAuthGameMode()) : nullptr;
    if (!GameMode)
    {
        return;
    }

    const bool bInVehicle = OtherActor->IsA<AMHVehiclePawn>();
    if (GameMode->CompleteCurrentObjective(bInVehicle) && bOneShot)
    {
        bConsumed = true;
        SetActorEnableCollision(false);
        SetActorHiddenInGame(true);
    }
}
