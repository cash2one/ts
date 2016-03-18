//////////////////////////////////////////////////////////////////////////
//<-����ȥ     ;      ->����Ϣ
/////////////////////////////////////////////////////////////////////////
// LoginServer 2 User
struct LS2U_LoginResult <-
{
	int8	result;				// 0Ϊ��¼�ɹ�����0Ϊ��¼ʧ��ԭ��
	uint64	accountID;
	string	identity;
	string  msg;					//��Ϊ�գ��ֻ�����չʾ
};
//-define( LoginResultSucc, 0 ).
//-define( LoginResultSearchFail, 1 ).
//-define( LoginResultAccountDenied, 2 ).%%������
//-define( LoginResultDbErr, 9 ).

struct GameServerInfo
{
	int16  lineid;
	string  name;
	string	ip;
	int16	port;
	int8	state;
};
//#define GameServer_State_UnCheckPass			0		//����
//#define GameServer_State_CheckPass				1		//��
//#define GameServer_State_Running					2		//����
//#define GameServer_State_ForbidLogin			3		//ά��
//#define GameServer_State_Closed					4		//ά��
//#define GameServer_State_SpecCanVisable			5	//������Ա�ɼ�
struct LS2U_GameLineServerList <-
{
	vector<GameServerInfo>	gameServers;
};
//������·�б�
struct U2LS_RequestGSLine ->
{	
}

struct LS2U_LoginQue <-
{
	uint64	currentNumber;//�Լ��ڶ����е����
};


//gs����GameServerInfo
struct GS2U_ChangeLineResponse <-
{
	vector<GameServerInfo>	gameServers; //��·�б�
	string	identity; //��֤��
};


//////////////////////////////////////////////////////////////////////////
// User 2 LoginServer

struct U2LS_Login_Normal ->
{
	string	platformAccount;		// ƽ̨�ʺţ���Ϸ���ʺ���ƽ̨id���󶨴�����
	string 	platformName;			// ƽ̨��
	string	platformNickName;		// ƽ̨�ǳƣ�û�о���մ�
	int64	time;
	string	sign;
	string	deviceId;				// �������ɣ�ÿ���豸�����ظ�
	string	imei;					// �ֻ�����
	string	idfa;					// ƻ���ƺ�
	string	mac;					// ������
	string	extParam				// ��չ������
	int		versionRes;				// ��Դ�汾
	int		versionExe;				// ִ�г���汾
	int		versionGame;			// ��Ϸ�汾����
	int		versionPro;				// Э��汾
};

// funcell web��Ϣ
struct Web2LS_Crypto ->
{
	string	bodyJsonStr;		// ������Ϣ��
};
// funcell web��Ϣ
struct Web2LS_Normal ->
{
	string	bodyJsonStr;		// δ������Ϣ��
};

// funcell �ظ�web��Ϣ
struct LS2Web_CryptoAck <-
{
	string	bodyJsonStr;		// ������Ϣ��
};

// funcell �ظ�web��Ϣ
struct LS2Web_NormalAck <-
{
	string	bodyJsonStr;		// δ������Ϣ��
};

