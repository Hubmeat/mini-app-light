import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class WechatLoginDto {
  @IsString()
  @IsNotEmpty()
  code!: string;
}

export class SendCodeDto {
  @Matches(/^1\d{10}$/, { message: '手机号格式不正确' })
  phone!: string;
}

export class PhoneLoginDto {
  @Matches(/^1\d{10}$/, { message: '手机号格式不正确' })
  phone!: string;

  @IsString()
  @IsNotEmpty()
  code!: string;
}
