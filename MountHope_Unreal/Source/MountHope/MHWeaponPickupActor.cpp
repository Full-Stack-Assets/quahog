#include "MHWeaponPickupActor.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Kismet/GameplayStatics.h"
#include "MHPlayerCharacter.h"

AMHWeaponPickupActor::AMHWeaponPickupActor()
{
    PrimaryActorTick.bCanEverTick = false;

    InteractionSphere = CreateDefaultSubobject<USphereComponent>(TEXT("InteractionSphere"));
    RootComponent = InteractionSphere;
    InteractionSphere->SetSphereRadius(InteractionRadius);
    InteractionSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    InteractionSphere->SetCollisionResponseToAllChannels(ECR_Ignore);
    InteractionSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);

    DisplayMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("DisplayMesh"));
    DisplayMesh->SetupAttachment(RootComponent);
    DisplayMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void AMHWeaponPickupActor::BeginPlay()
{
    Super::BeginPlay();
    InteractionSphere->SetSphereRadius(InteractionRadius);
}

FText AMHWeaponPickupActor::GetInteractionPrompt_Implementation() const
{
    return FText::FromString(TEXT("Pick up pistol"));
}

void AMHWeaponPickupActor::Interact_Implementation(APawn* InstigatorPawn)
{
    AMHPlayerCharacter* PlayerCharacter = Cast<AMHPlayerCharacter>(InstigatorPawn);
    if (!PlayerCharacter)
    {
        return;
    }

    PlayerCharacter->PickUpPistol(AmmoAmount);
    UGameplayStatics::PlaySound2D(this, PickupSound);
    Destroy();
}
