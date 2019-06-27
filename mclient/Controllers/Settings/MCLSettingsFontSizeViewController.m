//
//  MCLSettingsFontSizeViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsFontSizeViewController.h"

#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLLoadingView.h"
#import "MCLMessageListViewController.h"
#import "MCLMessage.h"

@interface MCLSettingsFontSizeViewController ()

@property (nonatomic) float lastSliderValue;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *topContainerView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *bottomContainerView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIImageView *fontDecreaseImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fontIncreaseImageView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation MCLSettingsFontSizeViewController

#pragma mark - Initializers

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Setup Font Size", nil);

    [self configureNavigationBar];
    [self configureSlider];
    [self configureWebView];

    [self themeChanged:nil];
}

- (void)configureNavigationBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(resetButtonPressed:)];
}

- (void)configureSlider
{
    float defaultFontSize = [self defaultFontSize];
    float fontSize = (float)[self.bag.settings integerForSetting:MCLSettingFontSize];
    if (!fontSize) {
        fontSize = defaultFontSize;
    }
    if (fontSize == defaultFontSize) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }

    self.slider.minimumValue = 1.0f;
    self.slider.maximumValue = 6.0f;
    self.slider.continuous = YES;
    self.slider.value = fontSize;

    [self.slider addTarget:self
                    action:@selector(sliderValueChanged:)
          forControlEvents:UIControlEventValueChanged];

    self.fontDecreaseImageView.image = [self.fontDecreaseImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.fontIncreaseImageView.image = [self.fontIncreaseImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)configureWebView
{
    [self.webView addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    self.webView.delegate = self;
    self.webView.opaque = NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    for (id subview in self.webView.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
            [subview removeFromSuperview];
        }
    }
}

#pragma mark - Actions

- (void)resetButtonPressed:(UIBarButtonItem *)sender
{
    self.slider.value = [self defaultFontSize];;
    [self sliderValueChanged:self.slider];
}

- (void)sliderValueChanged:(UISlider *)sender
{
    float newValue = roundf(sender.value);
    sender.value = newValue;
    if (newValue != self.lastSliderValue) {
        self.lastSliderValue = newValue;
        [self.bag.settings setInteger:(int)newValue forSetting:MCLSettingFontSize];
        [self loadPreviewMessage];
        [self.bag.soundEffectPlayer playTickSound];
        [self.delegate settingsFontSizeViewController:self fontSizeChanged:newValue];
        float defaultFontSize = [self defaultFontSize];
        self.navigationItem.rightBarButtonItem.enabled = newValue != defaultFontSize;
    }
}

- (void)loadPreviewMessage
{
    MCLMessage *previewMessage = [[MCLMessage alloc] init];
    previewMessage.textHtml = [self seamanDiaryPostingText];
    previewMessage.textHtmlWithImages = previewMessage.textHtml;
    NSString *previewText = [previewMessage messageHtmlWithTopMargin:55
                                                               width:self.view.bounds.size.width
                                                               theme:self.bag.themeManager.currentTheme
                                                             settings:self.bag.settings];
    [self.webView loadHTMLString:previewText baseURL:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    id <MCLTheme> currentTheme = self.bag.themeManager.currentTheme;

    self.view.backgroundColor = [currentTheme backgroundColor];

    self.fontDecreaseImageView.tintColor = [currentTheme textColor];
    self.fontIncreaseImageView.tintColor = [currentTheme textColor];

    [self loadPreviewMessage];
}

#pragma mark - Static data

- (float)defaultFontSize
{
    return (float)kSettingsDefaultFontSize;
}

- (NSString *)seamanDiaryPostingText
{
    return @"Bin heute extra früh aufgestanden um mein Baby abzuholen. Jetzt hab ich die Disc seit einer Stunde im DC und es ist noch nix passiert. Trotzdem ist es spannend. Klingt blöd, oder? Auf jeden Fall bin ich ziemlich gespannt, wann die Säcke ausschlüpfen. Ich beschimpfe sie jetzt schon per Micro, damit da keine politisch korrekten SozPäd-Penner rauskommen. Ich will das absolut Böse heranzüchten, schlimmer als YuzoKoshiroFan und Supreme zusammen! Ich halte Euch auf dem laufenden.. <br><br>Juhuuu!!! Nachdem der blöde Nautilus meine Larven (4 oder 5 Stück) gefressen hat, ist er wie wild rumgeflitzt und &#xB4;schien irgendwie krank zu sein. Nach einigen Minuten sind plötzlich kleine Fische mit menschlichen Gesichtern aus Ihm rausgeschwommen. Die Larven scheinen sich in seinem Körper entwickelt zu haben. Igitt!!!! Kleine Parasitensäcke! Der Nautilus ist danach gestorben.. Die Fische (Gillmen laut Anleitung) können schon kommunizieren. Sie beherrschen einfache Vokabeln wie &quot;Cool&quot; &quot;Seaman&quot;, &quot;Kiss my ass&quot; u.s.w. Seit einer Stunde tut sich aber nix. Diese ignoranten Säcke! Einer von Ihnen schaut mich immer ganz verachtungsvoll an. Wenn ich mit ihm rede, erwidert er irgendein Kauderwelsch und schaut böse. Der wird sich noch wundern... Wer mir blöd kommt wird es bereuen! Kleine undankbare Sau! Ich muß Ihn bestrafen ohne daß es die anderen merken. Ich will nicht ihren Hass auf mich ziehen, wenn ich den ungehorsamen Sack quäle! Mir fällt schon noch was ein.... <br><br>AAARGH! <br>Ich habe gerade mein DC angeworfen und mußte feststellen, daß zwei &quot;Gillmen&quot;tot sind! Leider hat es den Regimekritikerfisch nicht erwischt. Drecksack, guckt immer noch böse drein und wirft mir Wörter wie &quot;Glaytor&quot; und &quot;WabblWabbl&quot; an den Kopf! <br>Ich bin soweit das Leben des anderen Fisches zu opfern, nur um den aufmüpfigen Sack plattzumachen! Ich hab schon einen Felsen auf die Sauerstoffzufuhr geschoben, aber es scheint diesen Pennerfisch nicht zu jucken. Der andere Fisch hat ein &quot;weibliches&quot; Gesicht. Ihr widme ich jetzt meine gesamte Aufmerksamkeit. Wenn Darwin Recht hat, müßte der stärkere der beiden überleben. Deshalb ist jetzt mein oberstes Ziel den Drecksackfisch zu schwächen und den Weiberfisch zu unterstützen. <br>Ich rede nur noch mit dem Weiberfisch, aber der Regimekritiker mischt sich immer ein und babbelt wirres Zeugs. Zum Glück kann ich Ihn maßregeln in dem ich ihm den Finger in die Polygonhoden dresche! Den Weibsfisch nenne ich jetzt &quot;Mandy&quot;Wie die Weiber in der Ex-DDR)! Sie ist sehr angetan von mir und sagt immer ich wäre cool! <br>Wie kann ein virtuelles Vieh wissen, daß ich der coolste King der Welt bin? <br>Da waren Meisterprogrammierer am Werk! Mandy scheint müde zu sein und daher mache ich das Licht aus. Ob die Titten kriegt? Jetzt quäle ich erst mal den &quot;Oli P.-Fisch........... <br><br>NEEEIN! <br>Der Weiberfisch ist gar kein Weiberfisch! Er scheint doch männlich zu sein und hat halt feminine Züge. Der Regimekritikerfisch ist immer noch wohlauf. <br>Die rstlichen Larven(Mushrooms) die noch rumschwommen sind verschwunden. <br>Da sie Ihr Futter nicht fressen, nehme ich an die zwei Gillmen haben die Larven gefressen. Kannibalistische Drecksaufische! Ich würde sie gerne sterben sehen aber ich habe keinen Bock wieder neue zu züchten. Sie können jetzt besser sprechen. <br>Fish, Yes, No, Seaman, Fine u.s.w. Ich habe jetzt das Licht ausgemacht und die Wassertemperatur auf 35 Grad erhöht. Das sind 15 Grad mehr als der Idealwert. <br>Ich will daß sie mich hassen! Ich suche nach einem Weg sie gegeneinander aufzuhetzen, aber ich weiß nicht wie. Ich muß herausfinden ob beide wissen wie sie heißen oder wer sie sind. Dann wird gezielt gemobbt! &quot;Regimekritikerfish is bad!&quot;, &quot;He likes Wolfgang Petry&quot;, &quot;Mandyfish is cool!&quot; &quot;You are better than the Assnosefish!&quot; <br>Wenn ich einen Fisch quäle, haßt mich dann der andere auch? Sehen sie sich als kollektives Wesen? Sind es eigene Persönlichkeiten? Ich muß es wissen. Ich habe mich in 2 Tagen zu einem Gott entwickelt. Herrscher über Leben und Tod! Ich würde gerne ins Aquarium pinkeln und die Fische dann auslachen. Ich brauche einen Verbündeten im Aquarium. Einen Aufseher der meine Befehle ausführt ohne zu mucken. <br>&quot;Aufseherfish! Show the Assholefish where the hammer hangs. Here you have vaseline. Use it wisely!&quot; <br>Die beiden Fische gehen mir echt auf den Sack, da sie nichts zu meiner Belustigung tun. Wenn ich &quot;PLAY&quot; sage schauen sie nur gelangweilt. Ich bring euch schon noch zum tanzen... <br><br>Igitt! <br>Ich hatte ein fürchterliches Erlebnis! Der Arschlochfisch schwamm unter den Pseudoweiberfisch und bohrte ihm seinen &quot;Schlauch&quot; in den Unterleib. Zuerst dachte ich sie f...en und haben Spaß... <br>Doch der Weiberfisch schien in sich zusammenzufallen und stöhnte ganz komisch. <br>Dann schwebte der Weiberfisch mit dem Bauch nach oben an die Wasseroberfläche. <br>Nach einiger Zeit sank er dann auf den Grund. War das eklig! Der Drecksaufisch lächelte... Er wurde über 20 Minuten lang bestraft. Wassertemperatur 50 Grad. <br>Dauerndes Hoddensnipping und verbales Nonstopbeleidigen. Er grinst jetzt nicht mehr. <br>Nach einigen Stunden war er dann viel größer und hatte eine tiefe Männerstimme. <br>Er fragt jetzt dauernd Sachen und bildet ganze Sätze. Als ich &quot;Do you speak english&quot; sagte, erwiderte er &quot;Why do Americans think, that the whole world is talking their language?!&quot; Er hält mich für einen Ami! Sehr gut ich kann also inkognito arbeiten. Ich snippte ihm noch mehrmals in die Eier und dann hab ich das Licht ausgeschalten. <br>Die Temperatur habe ich nochmals erhöht und jetzt werde ich mal sehen ob er noch so lustig drauf ist und mich weiterhin als &quot;Freak&quot; beschimpft. Es würde mich echt interessieren ob der Drecksack auch um seine Existenz bangen kann. Wird er mich anflehen um Futter und Zuneigung? Da noch der Kadaver des anderen Fisches rumliegt warte ich mit dem Füttern. Er soll seinen Weggefährten fressen! Welch dramatischer Zustand! Wenn die Außenwelt wüßte was für ein Schauspiel sich in meinen vier Wänden abspielt. Diese unwissenden Würmer! Morgen werde ich meiner geilen Nachbarin auf die Brüste snippen... <br><br>Oh mein Gott! <br>Ich bin am Ende und ich habe ein schrecklich schlechtes Gewissen. <br>Ich habe gestern Nacht eine Art Käfig mit Mottenlarven erhalten. <br>Sie dienen dem Gillmen als Nahrung. Es ind vier Raupen und eine verpuppt sich. <br>Da hab ich dann einpaar Larven ins Wasser geworfen und Drecksaufisch hat sie gefressen. Er ist jetzt ziemlich groß und verarscht mich dauernd. <br>Er fragte mich ob es stimmt, daß ich in der Sexindustrie arbeite(Kein Witz) und ob ich eine Freundin habe und so. Er ist ziemlich neugierig und vorlaut. <br>Die verpuppte Motte schlüpfte aus Ihrem Kokon und saß blöd rum. Der Mastdarmfisch hatte Hunger und quengelte dauernd. Ich wollte ihm die Motte aber nicht geben bevor sie neue Eier legt. Sonst hätte ich kein Futter mehr übrig. Da habe ich einfach die interne Uhr des DC um 10 Stunden vorgestellt. Jetzt war die Motte flügge, aber immer noch keine neuen Larven. Da dachte ich, daß man die Motte evtl. ins Aquarium werfen muß. Vielleicht schwirrt die über dem Wasser rum und es entsteht auch über dem Wasser bisschen Action. <br>Die Scheißmotte ist leider ersoffen und der Affenarschfisch will sie nichtmal fressen! Jetzt habe ich kein Futter mehr... Mein Plan: Ich stelle die Uhr nochmals vor und warte auf neu entstehende Larven. Am nächsten Tag war der Drecksaufisch fast tot. Er warf mir vor ich würde ihn umbringen wollen. Ich war am Boden zerstört. <br>Ich habe über einen Zeitraum von mehreren Stunden zusehen können wie er starb. <br>WAAAARUM!!!????? Gott warum hast du nicht mich genommen? Er war frei von Schuld...Ich habe Ihn auf dem Gewissen. Ich will auch sterben..Ich werde heute Abend sämtliche Kneipengäste töten und danach richte ich mich selbst. Sollte ich allerdings den Mut nicht aufbringen, werde ich morgen eine neue Brut erzeugen. <br>Es werden bessere Kreaturen sein und sie werden auch besser behandelt werden! <br>Allerdings werde ich mir einen Fisch aussuchen und dieser wird gequält! <br><br>Ich bin der King! <br>Ich habe eine neue Welt kreiert! Damit es nicht so lange dauert habe ich nach jedem Besuch des Aquariums die interne DC-Uhr um einen Tag vorgestellt. Nach 3 Stunden war ich dann soweit, wie sonst nach 4 Tagen! Vorher begangene Fehler wurden umgangen und jetzt habe ich 2 gesunde Erwachsenenfische! Im Mottenkäfig sitzt jetzt allerdings eine Spinne und scheint die Futtermotten zu fressen! Ich weiß nicht wo der Arachnoid (Ha, Fremdwort!) herkommt. War er in einem der Eier versteckt? Ich habe ja schon oft gehört, daß die Neger in Afrika beim Bananeneinpacken auch gerne mal eine Vogelspinne mit reintun. Im Supermarkt töten die Viecher dann den erstbesten Bananenkäufer. <br>Ich habe die Spinne dann einfach gepackt und ins Wasser geworfen. Der Fisch der sie aß wurde plötzlich krank?! Ich habe noch nicht rausgefunden wie und vor allem ob er sich wieder erholt. Seit diesem Ereignis haßt er mich und ich weiß jetzt, daß es für Ihn besser wäre zu sterben. Ich werde Ihn peinigen. Nach einem Hodensnipping und einem saftigen &quot;Asshole! You suck!&quot; antwortete er &quot;So does your mother!&quot; Dann knurrte er mich dauernd an. Er hat meine Mutter beleidigt. Ich habe Ihn daher verurteilt. Er wird gefoltert und seine Hoden werden wundgesnippt! His sufferings will be legendary in hell! Der andere Fisch hat goldene Schuppen und heißt &quot;Koochy&quot;. <br>Er reagiert auf seinen Namen und mag es mich auszufragen. Er hat mich gefragt ob ich meine Freundin schon betrogen habe. Ich verneinte, aber er beharrte darauf daß ich ein Hengst bin(Oh, come on you stud!&quot; Dann habe ich es zugegeben und er versprach mir es jedem weiterzuerzählen. Ein raffinierter Sack.. Er weiß daß ich auf ihn angewiesen bin da der andere Fisch ziemlich übel dran ist. Er weiß er kann sich jetzt einiges erlauben. Zuerst habe ich ihn beschimpft...&quot;You are hitler! You dirty nazi!&quot; Er antwortete: &quot; No, i look much better! Hairless Monkey!&quot; Ich muß seine Respektlosigkeit hinnehmen und abwarten ob der kranke Fisch sich erholt. Im Falle seiner Genesung werde ich Ihn aufpeppeln und &quot;Koochy&quot; töten! Wer mich einen haarlosen Affen nennt stirbt! <br>Irgendwas mache ich falsch! Jetzt hassen mich beide Fische. Nachdem mich &quot;Koochy&quot; als kranken Freak bezeichnet hat, schoß ich zurück... Ich snippte ihm mehrmals genau in die Fresse und dann sagte ich: &quot;Eat my shit!&quot; Jetzt kommt das unglaubliche! Er sah mich gelangweilt an und antwortete: &quot;You ordered it, here it comes!&quot; Dann hat er mir mit seinem Rüssel einen Batzen Scheiße entgegengeworfen welcher dann an der Scheibe nach unten glitt. Das war sein Todesurteil... Respektlose Sau! Ich habe den Felsen auf die Sauerstoffzufuhr gestellt und die Temperatur &quot;ein bißchen&quot; erhöht! Dann snippte ich minutenlang auf ihn ein. Zum Abschluß habe ich ihn für eine halbe Minute aus dem Wasser genommen. Während ich den Penner in der Hand hielt fing er an zu singen! &quot;I come from Alabama with the banjo on my knee...&quot;WIRKLICH WAHR!) Er wollte auf cool machen und da war ich Ihm behilflich dabei.. Ich habe abgespeichert und beim nächsten Besuch die Wassertemperatur bei 6 Grad belassen(15-20 sind ideal). Dann fragte ich fies &quot;is it cold?&quot; Sein Kommentar: &quot;I&#xB4;m just fine! Go play outside!&quot;. Dann hab ich ihm in die Eier gesnippt und das Licht ständig an und aus gemacht. Er schrie &quot;AAARGH! My eyes, my eyes, my eyes!&quot; Dann snippte ich ihn fast zu Tode. Es zeigte Wirkung! Ich hatte ihn gebrochen, diesen überheblichen, analfixierten Affenarsch! Als ich sagte &quot;You will die...I will kill you!&quot; rief er : &quot;I knew it! Let me out of here!&quot;. Hehe, wer lacht jetzt du niedrige Kreatur.. Ich habe dich gebrochen, dir deine Grenzen gezeigt und dich zum wimmernden Fischweib degradiert. Gegen Dich spricht der Dunkle Herrscher mit den magischen Kräften Hochdeutsch! Dein Leben hängt jetzt an einem seidenen Faden und es liegt an mir diesen zu kappen! Ich bin jetzt Gott.... Falls Koochy den morgigen Tag überlebt, werde ich entschlossener vorgehen müßen. <br>Ich darf keine Schwäche zeigen.. <br><br>SCHLEUDER";
}

@end
