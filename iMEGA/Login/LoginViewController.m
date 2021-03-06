#import "LoginViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "InputView.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGALogger.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSURL+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "CreateAccountViewController.h"
#import "TwoFactorAuthenticationViewController.h"
#import "PasswordView.h"

typedef NS_ENUM(NSInteger, TextFieldTag) {
    EmailTextFieldTag = 0,
    PasswordTextFieldTag
};

@interface LoginViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoTopLayoutConstraint;

@property (weak, nonatomic) IBOutlet InputView *emailInputView;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@end

@implementation LoginViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (UIDevice.currentDevice.iPhone4X) {
        self.logoTopLayoutConstraint.constant = 12.f;
    }
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logoTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(logoPressedFiveSeconds:)];
    longPressGestureRecognizer.minimumPressDuration = 5.0f;
    self.logoImageView.gestureRecognizers = @[tapGestureRecognizer, longPressGestureRecognizer];
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
    
    self.emailInputView.inputTextField.returnKeyType = UIReturnKeyNext;
    self.emailInputView.inputTextField.delegate = self;
    self.emailInputView.inputTextField.tag = EmailTextFieldTag;
    self.emailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
    if (@available(iOS 11.0, *)) {
        self.emailInputView.inputTextField.textContentType = UITextContentTypeUsername;
    }
    
    self.passwordView.passwordTextField.delegate = self;
    self.passwordView.passwordTextField.tag = PasswordTextFieldTag;
    if (@available(iOS 11.0, *)) {
        self.passwordView.passwordTextField.textContentType = UITextContentTypePassword;
    }
    
    [self.loginButton setTitle:AMLocalizedString(@"login", @"Login") forState:UIControlStateNormal];

    NSString *forgotPasswordString = AMLocalizedString(@"forgotPassword", @"An option to reset the password.");
    forgotPasswordString = [forgotPasswordString stringByReplacingOccurrencesOfString:@"?" withString:@""];
    forgotPasswordString = [forgotPasswordString stringByReplacingOccurrencesOfString:@"¿" withString:@""];
    [self.forgotPasswordButton setTitle:forgotPasswordString forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"login", nil)];
    
    if (self.emailString) {
        self.emailInputView.inputTextField.text = self.emailString;
        self.emailString = nil;
        
        [self.passwordView.passwordTextField becomeFirstResponder];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIDevice.currentDevice.iPhoneDevice) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)tapLogin:(id)sender {
    if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
        [MEGASdkManager createSharedMEGAChatSdk];
    }
    
    if ([[MEGASdkManager sharedMEGAChatSdk] initState] != MEGAChatInitWaitingNewSession) {
        MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:nil];
        if (chatInit != MEGAChatInitWaitingNewSession) {
            MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
            [[MEGASdkManager sharedMEGAChatSdk] logout];
        }
    }
    
    [self.emailInputView.inputTextField resignFirstResponder];
    [self.passwordView.passwordTextField resignFirstResponder];
    
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
            loginRequestDelegate.errorCompletion = ^(MEGAError *error) {
                if (error.type == MEGAErrorTypeApiEMFARequired) {
                    TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
                    twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationLogin;
                    twoFactorAuthenticationVC.email = self.emailInputView.inputTextField.text;
                    twoFactorAuthenticationVC.password = self.passwordView.passwordTextField.text;
                    
                    [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
                }
            };
            [[MEGASdkManager sharedMEGASdk] loginWithEmail:self.emailInputView.inputTextField.text password:self.passwordView.passwordTextField.text delegate:loginRequestDelegate];
        }
    }
}

- (IBAction)forgotPasswordTouchUpInside:(UIButton *)sender {
    [[NSURL URLWithString:@"https://mega.nz/recovery"] mnz_presentSafariViewController];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)logoTappedFiveTimes:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [Helper enableOrDisableLog];
    }
}

- (void)logoPressedFiveSeconds:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [Helper changeApiURL];
    }
}

- (BOOL)validateForm {
    BOOL valid = YES;
    if (![self validateEmail]) {
        [self.emailInputView.inputTextField becomeFirstResponder];
        
        valid = NO;
    }
    
    if (![self validatePassword]) {
        if (valid) {
            [self.passwordView.passwordTextField becomeFirstResponder];
        }
        
        valid = NO;
    }
    
    return valid;
}

- (BOOL)validateEmail {
    BOOL validEmail = self.emailInputView.inputTextField.text.mnz_isValidEmail;
    
    if (validEmail) {
        [self.emailInputView setErrorState:NO withText:AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email")];
    } else {
        [self.emailInputView setErrorState:YES withText:AMLocalizedString(@"emailInvalidFormat", @"Enter a valid email")];
    }
    
    return validEmail;
}

- (BOOL)validatePassword {
    BOOL validPassword = !self.passwordView.passwordTextField.text.mnz_isEmpty;
    
    if (validPassword) {
        [self.passwordView setErrorState:NO];
    } else {
        [self.passwordView setErrorState:YES withText:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
    }

    return validPassword;
}

- (NSString *)timeFormatted:(NSUInteger)totalSeconds {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    NSString *currentLanguageID = [[LocalizationSystem sharedLocalSystem] getLanguage];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:currentLanguageID];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:totalSeconds];
    
    return [dateFormatter stringFromDate:date];
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField.tag == PasswordTextFieldTag) {
        self.passwordView.toggleSecureButton.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case EmailTextFieldTag:
            [self validateEmail];
            
            break;
            
        case PasswordTextFieldTag:
            self.passwordView.passwordTextField.secureTextEntry = YES;
            [self.passwordView configureSecureTextEntry];
            [self validatePassword];
            
            break;
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    switch (textField.tag) {
        case EmailTextFieldTag:
            [self.emailInputView setErrorState:NO withText:AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email")];
            break;
            
        case PasswordTextFieldTag:
            [self.passwordView setErrorState:NO];
            break;
            
        default:
            break;
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch (textField.tag) {
        case EmailTextFieldTag:
            [self.passwordView.passwordTextField becomeFirstResponder];
            break;
            
        case PasswordTextFieldTag:
            [self.passwordView.passwordTextField resignFirstResponder];
            [self tapLogin:self.loginButton];            
            break;
            
        default:
            break;
    }
    
    return YES;
}

@end
