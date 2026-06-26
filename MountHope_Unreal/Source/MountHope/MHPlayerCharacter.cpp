#include "MHPlayerCharacter.h"

#include "Camera/CameraComponent.h"
#include "Components/InputComponent.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"
#include "MHInteractable.h"

AMHPlayerCharacter::AMHPlayerCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 450.0f;
    CameraBoom->bUsePawnControlRotation = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 540.0f, 0.0f);
    GetCharacterMovement()->MaxWalkSpeed = 450.0f;
    GetCharacterMovement()->BrakingDecelerationWalking = 1800.0f;
}

void AMHPlayerCharacter::BeginPlay()
{
    Super::BeginPlay();
}

void AMHPlayerCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
}

void AMHPlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AMHPlayerCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AMHPlayerCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AMHPlayerCharacter::Turn);
    PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AMHPlayerCharacter::LookUp);
    PlayerInputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &AMHPlayerCharacter::TryInteract);
    PlayerInputComponent->BindAction(TEXT("EnterExitVehicle"), IE_Pressed, this, &AMHPlayerCharacter::RequestEnterExitVehicle);
}

void AMHPlayerCharacter::TryInteract()
{
    TArray<FOverlapResult> Overlaps;
    const float RadiusUnrealUnits = InteractionRadiusMeters * 100.0f;
    const FCollisionShape InteractionShape = FCollisionShape::MakeSphere(RadiusUnrealUnits);
    FCollisionObjectQueryParams ObjectTypes;
    ObjectTypes.AddObjectTypesToQuery(ECC_Pawn);
    ObjectTypes.AddObjectTypesToQuery(ECC_WorldDynamic);

    if (!GetWorld()->OverlapMultiByObjectType(Overlaps, GetActorLocation(), FQuat::Identity, ObjectTypes, InteractionShape))
    {
        return;
    }

    for (const FOverlapResult& Overlap : Overlaps)
    {
        AActor* Candidate = Overlap.GetActor();
        if (Candidate != nullptr && Candidate != this && Candidate->GetClass()->ImplementsInterface(UMHInteractable::StaticClass()))
        {
            IMHInteractable::Execute_Interact(Candidate, this);
            return;
        }
    }
}

void AMHPlayerCharacter::RequestEnterExitVehicle()
{
    // Vehicle possession will hand off here once the first Chaos vehicle pawn exists.
}

void AMHPlayerCharacter::MoveForward(float Value)
{
    if (Controller == nullptr || FMath::IsNearlyZero(Value))
    {
        return;
    }

    const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
}

void AMHPlayerCharacter::MoveRight(float Value)
{
    if (Controller == nullptr || FMath::IsNearlyZero(Value))
    {
        return;
    }

    const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
}

void AMHPlayerCharacter::Turn(float Value)
{
    AddControllerYawInput(Value);
}

void AMHPlayerCharacter::LookUp(float Value)
{
    AddControllerPitchInput(Value);
}
