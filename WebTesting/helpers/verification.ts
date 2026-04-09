import { ImapFlow } from 'imapflow';

export async function EmailVerificationLink(testEmail: string) {
    const client = new ImapFlow({
        host: 'imap.gmail.com',
        port: 993,
        secure: true,
        auth: {
            user: 'beatzatesting@gmail.com',
            pass: 'yzrb inut jspe gbdd' // Store this in your .env file!
        }
    });
    await client.connect();
    const lock = await client.getMailboxLock('INBOX');
    let verificationLink: string | null = null;
    try {
        const ids = await client.search({ to: testEmail });
        if (!ids || ids.length === 0) {
            throw new Error('No verification email found');
        }

        const message = await client.fetchOne(ids[ids.length - 1], { source: true, envelope: true });
        if (!message || !message.source) {
            throw new Error('Verification email payload not found');
        }

        const emailBody = message.source.toString();
        const requiredText = 'Confirm your email by clicking here.';

        // Match anchor tags and pick the one with the required visible text.
        const anchorRegex = /<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)<\/a>/gis;
        let anchorMatch: RegExpExecArray | null;

        while ((anchorMatch = anchorRegex.exec(emailBody)) !== null) {
            const href = anchorMatch[1];
            const anchorText = anchorMatch[2]
                .replace(/<[^>]+>/g, '')
                .replace(/\s+/g, ' ')
                .trim();

            if (anchorText === requiredText) {
                verificationLink = href;
                break;
            }
        }

        // Fallback for emails where href/text may be split by soft line breaks.
        if (!verificationLink) {
            const normalizedBody = emailBody
                .replace(/=\r?\n/g, '')
                .replace(/=3D/g, '=');

            const normalizedMatch = normalizedBody.match(
                /<a\b[^>]*href=["']([^"']+)["'][^>]*>\s*Confirm your email by clicking here\.\s*<\/a>/i
            );
            verificationLink = normalizedMatch?.[1] ?? null;
        }

        if (!verificationLink) {
            throw new Error(`No hyperlink found for text: "${requiredText}"`);
        }

        verificationLink = verificationLink
            .replace(/&amp;/g, '&')
            .replace(/=3D/g, '=')
            .replace(/=\r?\n/g, '');

        console.log('Verification email subject:', message.envelope?.subject ?? '(no subject)');
        return verificationLink;

    } finally {
        lock.release();
        await client.logout();
    }
}

export async function EmailVerificationOtp(testEmail: string): Promise<string> {
    const client = new ImapFlow({
        host: 'imap.gmail.com',
        port: 993,
        secure: true,
        auth: {
            user: 'beatzatesting@gmail.com',
            pass: 'yzrb inut jspe gbdd' // Store this in your .env file!
        }
    });
    await client.connect();
    const lock = await client.getMailboxLock('INBOX');

    try {
        const ids = await client.search({ to: testEmail });
        if (!ids || ids.length === 0) {
            throw new Error('No OTP email found');
        }

        const message = await client.fetchOne(ids[ids.length - 1], { source: true, envelope: true });
        if (!message || !message.source) {
            throw new Error('OTP email payload not found');
        }

        const emailBody = message.source.toString();

        const normalizedBody = emailBody
            .replace(/=\r?\n/g, '')
            .replace(/=3D/g, '=');

        const textBody = normalizedBody
            .replace(/<style[\s\S]*?<\/style>/gi, ' ')
            .replace(/<script[\s\S]*?<\/script>/gi, ' ')
            .replace(/<[^>]+>/g, ' ')
            .replace(/&nbsp;/gi, ' ')
            .replace(/&amp;/gi, '&')
            .replace(/\s+/g, ' ')
            .trim();

        const phraseMatch = textBody.match(/6-digit code is[:\s]*([0-9][0-9\s]{4,}[0-9])/i);
        let otp = phraseMatch?.[1]?.replace(/\D/g, '').slice(0, 6);

        if (!otp || otp.length !== 6) {
            const genericMatch = textBody.match(/\b([0-9](?:\s*[0-9]){5})\b/);
            otp = genericMatch?.[1]?.replace(/\D/g, '') ?? '';
        }

        if (!otp || otp.length !== 6) {
            throw new Error('Could not find 6-digit OTP in email');
        }

        console.log('OTP email subject:', message.envelope?.subject ?? '(no subject)');
        return otp;

    } finally {
        lock.release();
        await client.logout();
    }
}

export async function EmailResetPass(testEmail: string): Promise<string> {
    const client = new ImapFlow({
        host: 'imap.gmail.com',
        port: 993,
        secure: true,
        auth: {
            user: 'beatzatesting@gmail.com',
            pass: 'yzrb inut jspe gbdd' // Store this in your .env file!
        }
    });
    await client.connect();
    const lock = await client.getMailboxLock('INBOX');
    let resetLink: string | null = null;

    try {
        const ids = await client.search({ to: testEmail });
        if (!ids || ids.length === 0) {
            throw new Error('No reset password email found');
        }

        const message = await client.fetchOne(ids[ids.length - 1], { source: true, envelope: true });
        if (!message || !message.source) {
            throw new Error('Reset password email payload not found');
        }

        const emailBody = message.source.toString();
        const requiredText = 'Reset Password';

        const anchorRegex = /<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)<\/a>/gis;
        let anchorMatch: RegExpExecArray | null;

        while ((anchorMatch = anchorRegex.exec(emailBody)) !== null) {
            const href = anchorMatch[1];
            const anchorText = anchorMatch[2]
                .replace(/<[^>]+>/g, '')
                .replace(/\s+/g, ' ')
                .trim();

            if (anchorText === requiredText) {
                resetLink = href;
                break;
            }
        }

        // Fallback for emails where href/text may be split by soft line breaks.
        if (!resetLink) {
            const normalizedBody = emailBody
                .replace(/=\r?\n/g, '')
                .replace(/=3D/g, '=');

            const normalizedMatch = normalizedBody.match(
                /<a\b[^>]*href=["']([^"']+)["'][^>]*>\s*Reset Password\s*<\/a>/i
            );
            resetLink = normalizedMatch?.[1] ?? null;
        }

        if (!resetLink) {
            throw new Error(`No hyperlink found for text: "${requiredText}"`);
        }

        resetLink = resetLink
            .replace(/&amp;/g, '&')
            .replace(/=3D/g, '=')
            .replace(/=\r?\n/g, '');

        console.log('Reset password email subject:', message.envelope?.subject ?? '(no subject)');
        return resetLink;

    } finally {
        lock.release();
        await client.logout();
    }
}