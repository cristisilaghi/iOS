
#import "SettingsTableViewController.h"

#import "LTHPasscodeViewController.h"
#import "SVProgressHUD.h"

#import "CameraUploads.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "NSURL+MNZCategory.h"

@interface SettingsTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDictionary *languagesDictionary;
@property (weak, nonatomic) NSString *selectedLanguage;

@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *securityOptionsLabel;

@property (weak, nonatomic) IBOutlet UILabel *fileManagementLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *languageLabel;

@property (weak, nonatomic) IBOutlet UILabel *helpLabel;

@property (weak, nonatomic) IBOutlet UILabel *privacyPolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsOfServiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataProtectionRegulationLabel;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *language = [[LocalizationSystem sharedLocalSystem] getLanguage];
    if (language) {
        self.selectedLanguage = language;
    } else {
        self.selectedLanguage = nil;
    }
    
    self.languagesDictionary = @{@"ar":@"العربية",
                            @"bg":@"български език",
                            @"cs":@"Čeština",
                            @"de":@"Deutsch",
                            @"en":@"English",
                            @"es":@"Español",
                            @"fa":@"فارسی",
                            @"fi":@"Suomi",
                            @"fr":@"Français",
                            @"he":@"עברית",
                            @"id":@"Bahasa Indonesia",
                            @"it":@"Italiano",
                            @"ja":@"日本語",
                            @"ko":@"한국어",
                            @"nl":@"Nederlands",
                            @"pl":@"Język Polski",
                            @"pt-br":@"Português Brasileiro",
                            @"pt":@"Português",
                            @"ro":@"Română",
                            @"ru":@"Pусский язык",
                            @"sk":@"Slovenský",
                            @"sl":@"Slovenščina",
                            @"sr":@"српски језик",
                            @"sv":@"Svenska",
                            @"th":@"ไทย",
                            @"tl":@"Tagalog",
                            @"tr":@"Türkçe",
                            @"uk":@"українська мова",
                            @"vi":@"Tiếng Việt",
                            @"zh-Hans":@"简体中文",
                            @"zh-Hant":@"中文繁體"};
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateUI];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)updateUI {
    self.navigationItem.title = AMLocalizedString(@"settingsTitle", @"Title of the Settings section");
    
    self.cameraUploadsLabel.text = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    self.cameraUploadsDetailLabel.text = ([[CameraUploads syncManager] isCameraUploadsEnabled] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    self.chatLabel.text = AMLocalizedString(@"chat", @"Chat section header");
    self.chatDetailLabel.text = ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    
    self.passcodeLabel.text = AMLocalizedString(@"passcode", nil);
    self.passcodeDetailLabel.text = ([LTHPasscodeViewController doesPasscodeExist] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    self.securityOptionsLabel.text = AMLocalizedString(@"securityOptions", @"Title of the Settings section where you can configure security details of your MEGA account");
    
    self.fileManagementLabel.text = AMLocalizedString(@"File Management", @"A section header which contains the file management settings. These settings allow users to remove duplicate files etc.");
    self.advancedLabel.text = AMLocalizedString(@"advanced", @"Title of one of the Settings sections where you can configure 'Advanced' options");
    
    self.aboutLabel.text = AMLocalizedString(@"about", @"Title of one of the Settings sections where you can see things 'About' the app");
    self.languageLabel.text = AMLocalizedString(@"language", @"Title of one of the Settings sections where you can set up the 'Language' of the app");
    
    self.helpLabel.text = AMLocalizedString(@"help", @"Menu item");
    
    self.privacyPolicyLabel.text = AMLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'");
    self.termsOfServiceLabel.text = AMLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'");
    self.dataProtectionRegulationLabel.text = AMLocalizedString(@"dataProtectionRegulationLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Data Protection Regulation'");
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: //Camera Uploads, Chat
        case 1: //Pascode, Security Options
        case 2: //File management - Advanced
        case 3: //About, Language
        case 4: //Help
            break;
            
        case 5: { //Privacy Policy, Terms of Service
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                if (indexPath.row == 0) {
                    [[NSURL URLWithString:@"https://mega.nz/privacy"] mnz_presentSafariViewController];
                    break;
                } else if (indexPath.row == 1) {
                    [[NSURL URLWithString:@"https://mega.nz/terms"] mnz_presentSafariViewController];
                    break;
                } else if (indexPath.row == 2) {
                    [[NSURL URLWithString:@"https://mega.nz/gdpr"] mnz_presentSafariViewController];
                    break;
                }
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
